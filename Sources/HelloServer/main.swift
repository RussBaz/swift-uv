import UVCore
import UVServer

let server = UVServer()

let message = "HTTP/1.1 200 OK\r\nContent-Length: 19\r\nContent-Type: text/html\r\n\r\n<p>Hello World!</p>"

let status = await server.start { status in
    switch status {
    case let .success(success):
        Task {
            for await req in success.requests {
                let text = String(bytes: req, encoding: .utf8) ?? ""
                print("Recieved:\n\(text)")
                await success.write(UVTcpBuffer(string: message))
            }
            print("connection closed")
        }
    case let .failure(failure):
        print("failed to establish a connection: \(failure)")
    }
}

switch status {
case let .success(success):
    print("started the server with id \(success)")
case let .failure(failure):
    print("failed to start the server: \(failure)")
}

try await Task.sleep(until: .now.advanced(by: .seconds(120)))
print("The server is stopping because this is a sample server only meant to run for a few minutes.")
