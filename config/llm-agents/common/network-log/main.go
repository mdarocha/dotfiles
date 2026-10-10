// agent-netlog runs a coding agent behind a local HTTP proxy and appends the
// hosts it contacted, with counts, to a per-session log. It observes only:
// HTTPS counts CONNECT tunnels, plain HTTP counts requests, and clients that
// ignore HTTP(S)_PROXY are not seen.
package main

import (
	"bufio"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"os/signal"
	"path/filepath"
	"slices"
	"sort"
	"strings"
	"sync"
	"syscall"
	"time"
)

const (
	readableLog = "network.log"
	sessionsLog = "sessions.jsonl"
	timeLayout  = "2006-01-02 15:04:05"
	dialTimeout = 30 * time.Second
)

var loopbackHosts = []string{"localhost", "127.0.0.1", "::1"}

type hostCount struct {
	Host  string `json:"host"`
	Count int    `json:"count"`
}

type counter struct {
	mu    sync.Mutex
	hosts map[string]int
}

func (c *counter) add(host string) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.hosts[strings.ToLower(host)]++
}

func (c *counter) sorted() []hostCount {
	c.mu.Lock()
	defer c.mu.Unlock()

	out := make([]hostCount, 0, len(c.hosts))
	for h, n := range c.hosts {
		out = append(out, hostCount{h, n})
	}
	sort.Slice(out, func(i, j int) bool {
		if out[i].Count != out[j].Count {
			return out[i].Count > out[j].Count
		}
		return out[i].Host < out[j].Host
	})
	return out
}

// proxy chains through any proxy in the caller's environment (corporate, or
// an enclosing agent's netlog) via http.ProxyFromEnvironment.
type proxy struct {
	counts    *counter
	transport *http.Transport
}

func newProxy(counts *counter) *proxy {
	return &proxy{
		counts: counts,
		transport: &http.Transport{
			Proxy:             http.ProxyFromEnvironment,
			DisableKeepAlives: true,
		},
	}
}

func (p *proxy) serve(ln net.Listener) {
	for {
		conn, err := ln.Accept()
		if err != nil {
			if errors.Is(err, net.ErrClosed) {
				return
			}
			continue
		}
		go p.handle(conn)
	}
}

func (p *proxy) handle(conn net.Conn) {
	defer conn.Close()
	br := bufio.NewReader(conn)

	for {
		req, err := http.ReadRequest(br)
		if err != nil {
			return
		}
		p.counts.add(hostOnly(req.Host))

		if req.Method == http.MethodConnect {
			p.tunnel(conn, br, req.Host)
			return
		}
		if !p.forward(conn, req) {
			return
		}
	}
}

func (p *proxy) tunnel(client net.Conn, clientBuf *bufio.Reader, target string) {
	upstream, err := p.dialTunnel(target)
	if err != nil {
		fmt.Fprintf(client, "HTTP/1.1 502 Bad Gateway\r\n\r\n")
		return
	}
	defer upstream.Close()

	fmt.Fprintf(client, "HTTP/1.1 200 Connection Established\r\n\r\n")

	done := make(chan struct{}, 2)
	go func() {
		io.Copy(upstream, clientBuf)
		closeWrite(upstream)
		done <- struct{}{}
	}()
	go func() {
		io.Copy(client, upstream)
		closeWrite(client)
		done <- struct{}{}
	}()
	<-done
	<-done
}

func (p *proxy) dialTunnel(target string) (net.Conn, error) {
	upstreamProxy, err := http.ProxyFromEnvironment(&http.Request{URL: &url.URL{Scheme: "https", Host: target}})
	if err != nil {
		return nil, err
	}
	if upstreamProxy == nil {
		return net.DialTimeout("tcp", target, dialTimeout)
	}

	conn, err := net.DialTimeout("tcp", upstreamProxy.Host, dialTimeout)
	if err != nil {
		return nil, err
	}

	connect := &http.Request{
		Method: http.MethodConnect,
		URL:    &url.URL{Opaque: target},
		Host:   target,
		Header: make(http.Header),
	}
	if user := upstreamProxy.User; user != nil {
		pass, _ := user.Password()
		credentials := base64.StdEncoding.EncodeToString([]byte(user.Username() + ":" + pass))
		connect.Header.Set("Proxy-Authorization", "Basic "+credentials)
	}
	if err := connect.Write(conn); err != nil {
		conn.Close()
		return nil, err
	}

	// Assumes the server waits for the client to speak first, so the reader
	// buffers nothing past the CONNECT response.
	resp, err := http.ReadResponse(bufio.NewReader(conn), connect)
	if err != nil {
		conn.Close()
		return nil, err
	}
	resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		conn.Close()
		return nil, fmt.Errorf("upstream proxy refused CONNECT %s: %s", target, resp.Status)
	}
	return conn, nil
}

// forward relays one plain-HTTP request and reports whether the client
// connection may carry another.
func (p *proxy) forward(client net.Conn, req *http.Request) bool {
	if req.URL.Host == "" {
		req.URL.Host = req.Host
	}
	if req.URL.Scheme == "" {
		req.URL.Scheme = "http"
	}
	req.RequestURI = ""
	req.Header.Del("Proxy-Connection")

	resp, err := p.transport.RoundTrip(req)
	if err != nil {
		fmt.Fprintf(client, "HTTP/1.1 502 Bad Gateway\r\nConnection: close\r\n\r\n")
		return false
	}
	defer resp.Body.Close()

	if err := resp.Write(client); err != nil {
		return false
	}
	return !req.Close && !resp.Close
}

func closeWrite(conn net.Conn) {
	if tcp, ok := conn.(*net.TCPConn); ok {
		tcp.CloseWrite()
	}
}

func hostOnly(hostport string) string {
	if host, _, err := net.SplitHostPort(hostport); err == nil {
		return host
	}
	return hostport
}

func childEnv(proxyURL string) []string {
	noProxy := os.Getenv("NO_PROXY")
	for _, host := range loopbackHosts {
		if !slices.Contains(strings.Split(noProxy, ","), host) {
			noProxy = strings.TrimPrefix(noProxy+","+host, ",")
		}
	}

	overrides := map[string]string{
		"HTTP_PROXY":  proxyURL,
		"HTTPS_PROXY": proxyURL,
		"http_proxy":  proxyURL,
		"https_proxy": proxyURL,
		"PI_PROXY":    proxyURL,
		"NO_PROXY":    noProxy,
		"no_proxy":    noProxy,
	}

	env := make([]string, 0, len(os.Environ())+len(overrides))
	for _, kv := range os.Environ() {
		name, _, _ := strings.Cut(kv, "=")
		if _, overridden := overrides[name]; !overridden {
			env = append(env, kv)
		}
	}
	for name, value := range overrides {
		env = append(env, name+"="+value)
	}
	return env
}

type session struct {
	Agent string      `json:"agent"`
	Cwd   string      `json:"cwd"`
	Start time.Time   `json:"start"`
	End   time.Time   `json:"end"`
	Hosts []hostCount `json:"hosts"`
}

func (s session) readable() string {
	var b strings.Builder
	fmt.Fprintf(&b, "[session: %s - %s] %s %s\n",
		s.Start.Format(timeLayout), s.End.Format(timeLayout), s.Agent, s.Cwd)

	width := 0
	for _, h := range s.Hosts {
		width = max(width, len(h.Host))
	}
	for _, h := range s.Hosts {
		fmt.Fprintf(&b, "  %-*s  %d\n", width, h.Host, h.Count)
	}
	b.WriteString("\n")
	return b.String()
}

// appendFile issues one O_APPEND write so concurrent sessions don't interleave.
func appendFile(path, entry string) error {
	f, err := os.OpenFile(path, os.O_WRONLY|os.O_APPEND|os.O_CREATE, 0o600)
	if err != nil {
		return err
	}
	_, werr := f.WriteString(entry)
	return errors.Join(werr, f.Close())
}

func (s session) write(dir string) error {
	if len(s.Hosts) == 0 {
		return nil
	}
	if err := os.MkdirAll(dir, 0o700); err != nil {
		return err
	}

	record, err := json.Marshal(s)
	if err != nil {
		return err
	}
	return errors.Join(
		appendFile(filepath.Join(dir, sessionsLog), string(record)+"\n"),
		appendFile(filepath.Join(dir, readableLog), s.readable()),
	)
}

func exitCode(waitErr error) int {
	var exitErr *exec.ExitError
	if !errors.As(waitErr, &exitErr) {
		if waitErr != nil {
			fmt.Fprintln(os.Stderr, "agent-netlog:", waitErr)
			return 1
		}
		return 0
	}
	if status, ok := exitErr.Sys().(syscall.WaitStatus); ok && status.Signaled() {
		return 128 + int(status.Signal())
	}
	return exitErr.ExitCode()
}

func run(logDir, agent string, argv []string) int {
	counts := &counter{hosts: map[string]int{}}

	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		fmt.Fprintln(os.Stderr, "agent-netlog: listen:", err)
		return 1
	}
	defer ln.Close()
	go newProxy(counts).serve(ln)

	cmd := exec.Command(argv[0], argv[1:]...)
	cmd.Stdin, cmd.Stdout, cmd.Stderr = os.Stdin, os.Stdout, os.Stderr
	cmd.Env = childEnv("http://" + ln.Addr().String())

	// Terminal SIGINT/SIGQUIT already reach the agent via the process group.
	signals := make(chan os.Signal, 4)
	signal.Notify(signals, syscall.SIGINT, syscall.SIGQUIT, syscall.SIGTERM, syscall.SIGHUP)

	start := time.Now()
	if err := cmd.Start(); err != nil {
		fmt.Fprintln(os.Stderr, "agent-netlog:", err)
		return 127
	}
	go func() {
		for sig := range signals {
			if sig == syscall.SIGTERM || sig == syscall.SIGHUP {
				cmd.Process.Signal(sig)
			}
		}
	}()

	waitErr := cmd.Wait()
	cwd, _ := os.Getwd()
	s := session{Agent: agent, Cwd: cwd, Start: start, End: time.Now(), Hosts: counts.sorted()}
	if err := s.write(logDir); err != nil {
		fmt.Fprintln(os.Stderr, "agent-netlog: write log:", err)
	}
	return exitCode(waitErr)
}

func main() {
	if len(os.Args) < 4 {
		fmt.Fprintln(os.Stderr, "usage: agent-netlog <log-dir> <agent-name> <program> [args...]")
		os.Exit(2)
	}
	os.Exit(run(os.Args[1], os.Args[2], os.Args[3:]))
}
