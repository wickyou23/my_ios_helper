
enum Secrets {
    private static let fishSauce: [UInt8] = [
        
    ]

    static var gmsStatingApiKey: String {
        let encoded: [UInt8] = [
            
        ]

        return decode(encoded, cipher: fishSauce)
    }
    
    static var gmsUSProductionApiKey: String {
        let encoded: [UInt8] = [
            
        ]

        return decode(encoded, cipher: fishSauce)
    }
}
