#!/usr/bin/env swift

// Development-only script. Run from project root:
//   swift scripts/render-chime.swift
// Generates Sources/MultiTimerApp/Resources/chime.caf

import Foundation
import AVFoundation

let sampleRate: Double = 44100
let attackTime: Double = 0.01
// Harmonic amplitudes from Constants.Chime
let fundamentalAmp = 0.07
let secondHarmonicAmp = 0.02
let thirdHarmonicAmp = 0.007

func generateSamples(frequencies: [Double], duration: Double) -> [Float] {
    let count = Int(duration * sampleRate)
    var samples = [Float](repeating: 0, count: count)
    for freq in frequencies {
        for i in 0..<count {
            let t = Double(i) / sampleRate
            // Short linear attack, quadratic decay after peak
            let env: Double
            if t < attackTime {
                env = t / attackTime
            } else {
                let ratio = (t - attackTime) / (duration - attackTime)
                env = pow(1.0 - ratio, 1.5)
            }
            let phase = 2 * Double.pi * freq * t
            let signal = fundamentalAmp * sin(phase)
                + secondHarmonicAmp * sin(2 * phase)
                + thirdHarmonicAmp * sin(3 * phase)
            samples[i] += Float(signal * max(0, env))
        }
    }
    return samples
}

// "お" (E): C4-E4-G4 + melody E5, 0.45s
let eSamples = generateSamples(
    frequencies: [261.63, 329.63, 392.00, 659.25],
    duration: 0.45
)

// "ぜ" (D): B♭3-D4-F4 + melody D5, 0.90s
let dSamples = generateSamples(
    frequencies: [233.08, 293.66, 349.23, 587.33],
    duration: 0.90
)

let allSamples = eSamples + dSamples

let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
guard let buffer = AVAudioPCMBuffer(
    pcmFormat: format,
    frameCapacity: AVAudioFrameCount(allSamples.count)
) else {
    fputs("Failed to create PCM buffer\n", stderr)
    exit(1)
}
buffer.frameLength = buffer.frameCapacity

let channelData = buffer.floatChannelData![0]
for (i, v) in allSamples.enumerated() { channelData[i] = v }

let outputPath = "Sources/MultiTimerApp/Resources/chime.caf"
let outputURL = URL(fileURLWithPath: outputPath,
                    relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath))

do {
    try FileManager.default.createDirectory(
        at: outputURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    let file = try AVAudioFile(forWriting: outputURL, settings: format.settings)
    try file.write(from: buffer)
    print("chime.caf written to \(outputURL.path)")
} catch {
    fputs("Error: \(error)\n", stderr)
    exit(1)
}
