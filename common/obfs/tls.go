package obfs

import (
	"crypto/tls"
	"net"
)

// TLSObfsListener wraps a net.Listener with TLS obfuscation.
type TLSObfsListener struct {
	inner net.Listener
	conf  *tls.Config
}

// NewTLSObfsListener creates a TLS obfs listener.
// tlsConfig must have at least Certificates set.
func NewTLSObfsListener(inner net.Listener, tlsConfig *tls.Config) *TLSObfsListener {
	return &TLSObfsListener{inner: inner, conf: tlsConfig}
}

func (l *TLSObfsListener) Accept() (net.Conn, error) {
	conn, err := l.inner.Accept()
	if err != nil {
		return nil, err
	}
	return tls.Server(conn, l.conf), nil
}

func (l *TLSObfsListener) Close() error {
	return l.inner.Close()
}

func (l *TLSObfsListener) Addr() net.Addr {
	return l.inner.Addr()
}
