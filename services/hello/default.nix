_:
{ pkgs, inventory, ... }:
let
  helloScript = pkgs.writeScript "hello-http" ''
    #!${pkgs.python3}/bin/python3
    import http.server, socketserver

    class H(http.server.BaseHTTPRequestHandler):
        def do_GET(self):
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b'ok')
        def log_message(self, *a): pass

    socketserver.TCPServer(('127.0.0.1', 8899), H).serve_forever()
  '';
in
{
  systemd.services.hello-http = {
    description = "Simple HTTP 200 test server";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = helloScript;
      Restart = "always";
      DynamicUser = true;
    };
  };

  orbital.reverseProxy.hello = {
    domain = "hello.${inventory.domain}";
    port = 8899;
  };
}
