// Verschlüsselt die App für die Veröffentlichung.
// Aufruf:  swift werkzeug/verschluesseln.swift <app.html> <ausgabe/index.html>
// Das Passwort wird verdeckt abgefragt und nirgends gespeichert.
// Für Tests ohne Abfrage: Umgebungsvariable LEB_TESTPASSWORT.
import Foundation
import CryptoKit
import CommonCrypto

let args = CommandLine.arguments
guard args.count == 3 else { print("Aufruf: swift verschluesseln.swift <app.html> <index.html>"); exit(1) }
let here = URL(fileURLWithPath: args[0]).deletingLastPathComponent()
guard let plain = FileManager.default.contents(atPath: args[1]) else { print("App-Datei nicht gefunden: \(args[1])"); exit(1) }
guard var page = try? String(contentsOf: here.appendingPathComponent("sperrseite.html"), encoding: .utf8) else { print("sperrseite.html fehlt"); exit(1) }

func ask(_ prompt: String) -> String { guard let p = getpass(prompt) else { return "" }; return String(cString: p) }
let env = ProcessInfo.processInfo.environment
var pw = env["LEB_PASSWORT"] ?? env["LEB_TESTPASSWORT"] ?? ""
if pw.isEmpty {
    pw = ask("Passwort für die App: ")
    if pw.count < 10 { print("Bitte mindestens 10 Zeichen verwenden."); exit(1) }
    if ask("Passwort wiederholen: ") != pw { print("Die Passwörter stimmen nicht überein."); exit(1) }
}

func pbkdf2(_ pw: String, _ salt: [UInt8], _ it: UInt32) -> [UInt8]? {
    var key = [UInt8](repeating: 0, count: 32); let pwBytes = Array(pw.utf8)
    let rc = pwBytes.withUnsafeBufferPointer { p in p.baseAddress!.withMemoryRebound(to: Int8.self, capacity: pwBytes.count) { pp in
        CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2), pp, pwBytes.count, salt, salt.count, CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256), it, &key, key.count) } }
    return rc == kCCSuccess ? key : nil }

// Schutz vor Tippfehlern: Das Passwort muss die bisher veröffentlichte Fassung öffnen können (außer LEB_NEUES_PASSWORT=1)
if env["LEB_NEUES_PASSWORT"] != "1", let old = try? String(contentsOfFile: args[2], encoding: .utf8),
   let a = old.range(of: "/*DATEN*/{"), let b = old.range(of: "/*ENDE*/", range: a.upperBound..<old.endIndex),
   let j = try? JSONSerialization.jsonObject(with: Data(("{" + old[a.upperBound..<b.lowerBound]).utf8)) as? [String: Any],
   let s = j["s"] as? String, let d = j["d"] as? String, let it = j["i"] as? Int,
   let sd = Data(base64Encoded: s), let dd = Data(base64Encoded: d) {
    guard let k = pbkdf2(pw, [UInt8](sd), UInt32(it)), let box = try? AES.GCM.SealedBox(combined: dd), (try? AES.GCM.open(box, using: SymmetricKey(data: k))) != nil else {
        print("Abbruch: Dieses Passwort öffnet die bisher veröffentlichte App nicht. Für ein neues Passwort: LEB_NEUES_PASSWORT=1 zsh werkzeug/veroeffentlichen.sh"); exit(2) }
}

let iterations: UInt32 = 600_000
var salt = [UInt8](repeating: 0, count: 16)
guard SecRandomCopyBytes(kSecRandomDefault, salt.count, &salt) == errSecSuccess else { print("Zufall nicht verfügbar"); exit(1) }
var key = [UInt8](repeating: 0, count: 32)
let pwBytes = Array(pw.utf8)
let rc = pwBytes.withUnsafeBufferPointer { p in
    p.baseAddress!.withMemoryRebound(to: Int8.self, capacity: pwBytes.count) { pp in
        CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2), pp, pwBytes.count, salt, salt.count,
                             CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256), iterations, &key, key.count)
    }
}
guard rc == kCCSuccess else { print("Schlüsselableitung fehlgeschlagen"); exit(1) }

let box = try AES.GCM.seal(plain, using: SymmetricKey(data: key))   // Nonce (12) + Chiffrat + Tag (16)
let json = "{\"v\":1,\"i\":\(iterations),\"s\":\"\(Data(salt).base64EncodedString())\",\"d\":\"\(box.combined!.base64EncodedString())\"}"
let marker = "/*DATEN*/null/*ENDE*/"
guard page.contains(marker) else { print("Platzhalter in sperrseite.html fehlt"); exit(1) }
page = page.replacingOccurrences(of: marker, with: "/*DATEN*/" + json + "/*ENDE*/")
try page.write(toFile: args[2], atomically: true, encoding: .utf8)
print("Fertig: \(args[2]) ist verschlüsselt (\(page.utf8.count / 1024) KB).")
