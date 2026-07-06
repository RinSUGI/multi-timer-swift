import Foundation
import AVFoundation
import MultiTimerCore

public final class ChimePlayer: ChimePlaying {
    private var player: AVAudioPlayer?

    public init() {}

    // Call at startup to pre-initialize audio so the first playChime() has no latency (NFR-03).
    public func warmUp() {
        player = makePlayer()
        player?.prepareToPlay()
    }

    public func playChime() {
        if let existing = player, existing.isPlaying {
            // Concurrent finish: spin up a separate player instead of interrupting
            let overlap = makePlayer()
            overlap?.play()
        } else {
            if player == nil { player = makePlayer() }
            player?.play()
        }
    }

    private func makePlayer() -> AVAudioPlayer? {
        let url = Bundle.module.url(forResource: "chime", withExtension: "caf")
            ?? Bundle.main.url(forResource: "chime", withExtension: "caf")
        guard let url else { return nil }
        let p = try? AVAudioPlayer(contentsOf: url)
        p?.prepareToPlay()
        return p
    }
}
