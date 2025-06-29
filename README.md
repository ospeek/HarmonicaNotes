Harmonica Notes

Harmonica Notes is a compact educational mobile app that turns any phone or tablet into a 10-hole diatonic C-harmonica. Its simple two-row interface is designed for beginners learning hole numbers as well as for experienced players who want a quick musical notepad on the go.

⸻

1. Concept

Top Row (Draw)	Bottom Row (Blow)
−1 … −10	+1 … +10

Each on-screen button represents one hole on a standard 10-hole C harmonica.
	•	Press & hold* a button → the corresponding note sounds for as long as it is held.
	•	Release* → the note gently fades out, imitating the natural stop of a real reed.

Because the physical instrument produces different pitches when drawing in (negative numbers) versus blowing out (positive numbers), the two rows mimic that logic: the upper row (-) is “draw,” the lower row (+) is “blow.”  This visual model helps newcomers internalise hole numbers before learning bending, overblows, and other techniques.

⸻

2. Note Mapping (C Diatonic)

Hole	Blow (+)	Draw (−)
1	C4	D4
2	E4	G4
3	G4	B4
4	C5	D5
5	E5	F5
6	G5	A5
7	C6	B5
8	E6	D6
9	G6	F6
10	C7	A6

Tip: These are the standard Richter-tuned pitches; if you would like to support alternate tunings, see Extensions below.

⸻

3. Interaction & Audio Behaviour

3.1 Touch Gestures
	•	Tap & Hold – Starts note with a gentle 15 ms attack; sustain for duration of hold.
	•	Release – Triggers a 120 ms exponential release curve for a realistic reed shutdown.
	•	Multi-Touch – Users can hold multiple holes simultaneously to experiment with interval stacking and chords. 
		Note that it is not allowed to have in and out notes sound at the sime time. When an in button is pressed while an out button is being held, the
		out sound releases and the in sound attacks.

3.2 Sound Generation
	•	Synth - A warm additive synth with 3 detuned saw harmonics and light low-pass filtering is used, played through an ADSR envelope (Attack 15 ms, Decay 0 ms, Sustain 100 %, Release 120 ms).

3.3 Performance Optimisation
	•	Touch-to-sound pipeline uses platform-native low-latency audio engines (e.g. AVAudioEngine on iOS, AAudio/OpenSL ES on Android).

⸻

4. User Interface

Section	Element	Behaviour
Header	Title “Harmonica Notes”	Minimalist top bar with settings icon (⚙︎).
Main Grid	2 × 10 round-corner buttons	Responsive: each button expands to fill width. Labels «−1»…«−10» / «+1»…«+10».
Status Bar	Note read-out	Displays currently sounding pitch (e.g. “D4, Hole 1 Draw”).
Settings	Panel modal	show note names, dark/light theme.

Visual design follows Google Material 3 / iOS Human Interface guidelines: large hit targets (≥ 48 dp), high-contrast colours (WCAG AA), rounded corners (12 dp), and soft drop shadows.

⸻

5. Project Structure (Suggested)

/ios, /android, /lib            ←  cross-platform app source
  ├─ ui/                        ←  ButtonGrid, HoleButton widgets
  ├─ audio/                     ←  SamplePlayer, SynthVoice, NoteManager
  └─ data/samples/              ←  *.wav harmonica samples
/assets
LICENSE
README.md  ←  you are here

Framework: The sample codebase assumes Flutter for a single code-base; feel free to adapt to React Native, Swift UI, or Kotlin.

⸻

7. Building & Running

# Clone
$ git clone https://github.com/ospeek/harmonica-notes.git && cd harmonica-notes

# Install dependencies (Flutter)
$ flutter pub get

# Run on simulator / device
$ flutter run

For React Native or native projects, adjust commands accordingly.

⸻

8. Contributing

Pull requests are welcome! Please open an issue first to discuss major changes.  All code is formatted with dart format and checked by flutter analyze in CI.

⸻

9. License

This project is licensed under the MIT License. See LICENSE for details.

⸻

Happy harping! 🎵