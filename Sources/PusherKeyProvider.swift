
// TODO: this needs to be rethought once the auth call provides the decryptionKey

protocol PusherKeyProviding {
    var decryptionKey: String { get }
}

class PusherKeyProvider: PusherKeyProviding {
    
    let decryptionKey: String
    
    init(decryptionKey: String) {
        self.decryptionKey = decryptionKey
    }
}
