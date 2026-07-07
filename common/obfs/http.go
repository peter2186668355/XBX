// Package obfs implements simple-obfs compatible HTTP and TLS obfuscation.
//
// Wire format matches simple-obfs (github.com/shadowsocks/simple-obfs):
//   - Server sends HTTP 101 response immediately on connection
//   - Client sends HTTP GET request + SS data
//   - Server strips GET request headers, forwards remaining data
package obfs

import (
	"bufio"
	"crypto/rand"
	"encoding/base64"
	"fmt"
	"math/big"
	"net"
	"net/http"
	"time"
)

// HTTPObfsListener wraps a net.Listener with simple-obfs HTTP obfuscation.
type HTTPObfsListener struct {
	inner net.Listener
	host  string // expected Host header, empty = skip validation
}

// NewHTTPObfsListener creates an HTTP obfs listener.
// host is optional — when set, only requests with matching Host header are accepted.
func NewHTTPObfsListener(inner net.Listener, host string) *HTTPObfsListener {
	return &HTTPObfsListener{inner: inner, host: host}
}

func (l *HTTPObfsListener) Accept() (net.Conn, error) {
	conn, err := l.inner.Accept()
	if err != nil {
		return nil, err
	}
	return newHTTPObfsConn(conn, l.host)
}

func (l *HTTPObfsListener) Close() error {
	return l.inner.Close()
}

func (l *HTTPObfsListener) Addr() net.Addr {
	return l.inner.Addr()
}

// httpObfsConn handles the simple-obfs HTTP handshake on the server side:
// 1. Write HTTP 101 Switching Protocols response
// 2. Read and strip client HTTP GET request (headers until \r\n\r\n)
// 3. Remaining data after headers is buffered for subsequent reads
type httpObfsConn struct {
	net.Conn
	reader *bufio.Reader
}

func newHTTPObfsConn(conn net.Conn, host string) (*httpObfsConn, error) {
	c := &httpObfsConn{Conn: conn}

	// 1. Send HTTP 101 response immediately (simple-obfs: send_empty_response_upon_connection)
	resp := buildHTTP101Response()
	if _, err := conn.Write([]byte(resp)); err != nil {
		conn.Close()
		return nil, fmt.Errorf("obfs http write response: %w", err)
	}

	// 2. Read and strip client HTTP request headers
	c.reader = bufio.NewReader(conn)
	req, err := http.ReadRequest(c.reader)
	if err != nil {
		conn.Close()
		return nil, fmt.Errorf("obfs http read request: %w", err)
	}

	// 3. Validate Host header if configured (ponytail: simple-obfs --obfs-host compat)
	if host != "" && req.Host != host {
		conn.Close()
		return nil, fmt.Errorf("obfs http host mismatch: expected %s, got %s", host, req.Host)
	}

	return c, nil
}

func (c *httpObfsConn) Read(b []byte) (int, error) {
	return c.reader.Read(b)
}

// buildHTTP101Response generates a simple-obfs compatible HTTP 101 response.
// Format matches obfs_http.c http_response_template.
func buildHTTP101Response() string {
	major := randInt(11)
	minor := randInt(12)
	date := time.Now().UTC().Format("Mon, 02 Jan 2006 15:04:05 GMT")
	key := randomBase64(16)

	return fmt.Sprintf(
		"HTTP/1.1 101 Switching Protocols\r\n"+
			"Server: nginx/1.%d.%d\r\n"+
			"Date: %s\r\n"+
			"Upgrade: websocket\r\n"+
			"Connection: Upgrade\r\n"+
			"Sec-WebSocket-Accept: %s\r\n"+
			"\r\n",
		major, minor, date, key,
	)
}

func randInt(max int) int {
	n, err := rand.Int(rand.Reader, big.NewInt(int64(max)))
	if err != nil {
		return 0
	}
	return int(n.Int64())
}

func randomBase64(size int) string {
	b := make([]byte, size)
	rand.Read(b)
	return base64.StdEncoding.EncodeToString(b)
}
