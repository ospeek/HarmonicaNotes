import AVFoundation

enum EnvelopeState {
    case idle, attack, sustain, release
}

class SynthEngine {
    static let shared = SynthEngine()

    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode!

    private let attackTime: Float = 0.015
    private let releaseTime: Float = 0.120

    private var envelopeState: EnvelopeState = .idle
    private var envelopeTime: Float = 0
    private var envelopeValue: Float = 0

    private var phase0: Float = 0
    private var phase1: Float = 0
    private var phase2: Float = 0

    private let detuneCents: Float = 5.0
    private var detuneRatio: Float {
        return pow(2.0, detuneCents / 1200.0)
    }

    private let baseFreq: Float = 261.6256 // C4
    private var sampleRate: Double = 44100

    private var lpPrev: Float = 0
    private let lpAlpha: Float

    private init() {
        let output = engine.outputNode
        let format = output.outputFormat(forBus: 0)
        sampleRate = format.sampleRate

        let cutoff: Float = 5000
        let dt = 1.0 / Float(sampleRate)
        let rc = 1.0 / (2 * Float.pi * cutoff)
        lpAlpha = dt / (rc + dt)

        sourceNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let delta0 = self.baseFreq / Float(self.sampleRate)
            let delta1 = (self.baseFreq * self.detuneRatio) / Float(self.sampleRate)
            let delta2 = (self.baseFreq / self.detuneRatio) / Float(self.sampleRate)

            for frame in 0..<Int(frameCount) {
                let dt = 1.0 / Float(self.sampleRate)
                switch self.envelopeState {
                case .idle:
                    self.envelopeValue = 0
                case .attack:
                    self.envelopeTime += dt
                    if self.envelopeTime >= self.attackTime {
                        self.envelopeTime = 0
                        self.envelopeState = .sustain
                        self.envelopeValue = 1.0
                    } else {
                        self.envelopeValue = self.envelopeTime / self.attackTime
                    }
                case .sustain:
                    self.envelopeValue = 1.0
                case .release:
                    self.envelopeTime += dt
                    if self.envelopeTime >= self.releaseTime {
                        self.envelopeTime = 0
                        self.envelopeState = .idle
                        self.envelopeValue = 0
                    } else {
                        let frac = 1.0 - (self.envelopeTime / self.releaseTime)
                        self.envelopeValue = frac
                    }
                }

                func saw(_ phase: Float) -> Float {
                    return 2.0 * (phase - floor(phase + 0.5))
                }

                let s0 = saw(self.phase0)
                let s1 = saw(self.phase1)
                let s2 = saw(self.phase2)
                let raw = (s0 + s1 + s2) / 3.0

                let filtered = self.lpPrev + self.lpAlpha * (raw - self.lpPrev)
                self.lpPrev = filtered

                let sample = filtered * self.envelopeValue * 0.2

                for buffer in abl {
                    let ptr = UnsafeMutableBufferPointer<Float>(buffer)
                    ptr[frame] = sample
                }

                self.phase0 += delta0
                if self.phase0 >= 1.0 { self.phase0 -= 1.0 }
                self.phase1 += delta1
                if self.phase1 >= 1.0 { self.phase1 -= 1.0 }
                self.phase2 += delta2
                if self.phase2 >= 1.0 { self.phase2 -= 1.0 }
            }
            return noErr
        }

        engine.attach(sourceNode)
        engine.connect(sourceNode, to: engine.mainMixerNode, format: format)

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
        } catch {
            print("Audio engine start error: \(error)")
        }
    }

    func noteOn() {
        envelopeState = .attack
        envelopeTime = 0
    }

    func noteOff() {
        if envelopeState != .idle {
            envelopeState = .release
            envelopeTime = 0
        }
    }
}
