import UV

let server = UVServer()

let message = """
HTTP/1.1 200 OK
Content-Length: 12
Content-Type: text/plain; charset=utf-8

Hello World!

"""

let status = await server.start { status in
    switch status {
    case let .success(success):
        Task {
            for await req in success.requests {
                let text = req.asString
                print("Recieved:\n\(text)")
                guard let buffer = UVTcpBuffer(string: message) else { break }
                await success.write(buffer)
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
