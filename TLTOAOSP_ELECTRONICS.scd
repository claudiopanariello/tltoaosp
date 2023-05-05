//Claudio Panariello
//
// To learn the obscene art of suffering pain - PATCH
//
// cla.panariello@gmail.com
//
//////////////////// This patch does not rely on any particular object different from the usual basc SC extensions package.

/*
███████╗███████╗████████╗██╗   ██╗██████╗
██╔════╝██╔════╝╚══██╔══╝██║   ██║██╔══██╗
███████╗█████╗     ██║   ██║   ██║██████╔╝
╚════██║██╔══╝     ██║   ██║   ██║██╔═══╝
███████║███████╗   ██║   ╚██████╔╝██║
╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝

*/
(
s.options.memSize = 2.pow(19);
s.options.blockSize = 64;
Server.default.options.inDevice_("8M");
Server.default.options.outDevice_("8M");
Server.local.options.numOutputBusChannels = 10;
Server.local.options.numInputBusChannels = 8;
~numCones = 8;
s.boot;
)

//{Out.ar(0, SinOsc.ar(XLine.kr(20,2e4,10),0,0.7))}.play;

// Test the cones sending some white noise
// set the amplifiers so their output sounds pretty mushc the same / is comparable
({
	var numOut = 8;
	inf.do({
		|n|
		{Out.ar(n%numOut, WhiteNoise.ar(0.01)*EnvGen.kr(Env.perc, doneAction: 2))}.play;
		1.wait;
	})
}.fork;);

// Then set all piezo's gain to a level so that their input in the s-meter looks pretty much like the level in output (with WhiteNoise.ar(0.01))
8.do({|i| {Out.ar(i, WhiteNoise.ar(0.01))}.play});


/*
███████╗██╗   ██╗███╗   ██╗████████╗██╗  ██╗    ██████╗ ███████╗███████╗
██╔════╝╚██╗ ██╔╝████╗  ██║╚══██╔══╝██║  ██║    ██╔══██╗██╔════╝██╔════╝
███████╗ ╚████╔╝ ██╔██╗ ██║   ██║   ███████║    ██║  ██║█████╗  █████╗
╚════██║  ╚██╔╝  ██║╚██╗██║   ██║   ██╔══██║    ██║  ██║██╔══╝  ██╔══╝
███████║   ██║   ██║ ╚████║   ██║   ██║  ██║    ██████╔╝███████╗██║
╚══════╝   ╚═╝   ╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝    ╚═════╝ ╚══════╝╚═╝
*/

(
SynthDef(\learnSuffering, {
	arg gain = 0, busIn = 0, busOut = 0, lag = 0.5, rinf = 100, rsup = 200, amp_thresh = 0.2, centreFrequency = 100, rq = 0.5, impulseFrequency = 1, durGrain = 0.1, mix = 0, room = 1, filtered = 0, granularized = 1, lfFreq = 1, urLag = 1, levelOut = 0, delay = 0.1, bandwidth = 10, freqShift1 = 0, freqShift2 = 0, mul1 = 0, mul2 = 0, mul0 = 1, impuls = 1;
	var in_mic, input, rms, control, envfol_in, lfnoise, bandpass, foundFreq, rangeShift, grain, env, output;

	in_mic = LeakDC.ar(SoundIn.ar(busIn))*gain.lag3(0.5*urLag);
	input = Compander.ar(in_mic, in_mic); //input mic
	rms = RunningSum.rms(Amplitude.ar(input));
	control = (1-(rms.lag2(lag)));
	envfol_in = Lag.ar(rms, lag);

	lfnoise = LFNoise2.ar(lfFreq.lag3(0.1*urLag)).clip2.range(rinf.lag3(0.1*urLag), rsup.lag3(0.1*urLag));
	bandpass = DelayC.ar(BPF.ar(input, lfnoise, 0.1), 2, delay);

	foundFreq = (rinf+rsup)/2;
	rangeShift = BPF.ar(BPF.ar(bandpass, lfnoise, bandwidth/foundFreq), lfnoise, bandwidth/foundFreq);
	bandpass = Mix.new([
		bandpass*mul0.lag3(urLag),
		FreqShift.ar(rangeShift, freqShift1, 0, mul1.lag3(urLag)),
		FreqShift.ar(rangeShift, freqShift2, 0, mul2.lag3(urLag))]);

	grain = GrainIn.ar(
		numChannels: 1,
		trigger: Select.ar(impuls, [
			Dust.ar(impulseFrequency.lag3(1*urLag)),
			Impulse.ar(impulseFrequency.lag3(1*urLag))
		]), //Dust.ar(envfol_in.expexp(0.0001, 1.0, 80, 5)),
		dur: durGrain.lag3(1*urLag),//envfol_in.expexp(0.0001, 1.0, 0.1, 0.001),
		in: Mix.new([input*(1-filtered.lag3(0.1*urLag)), bandpass*filtered.lag3(0.1*urLag)])
	);

	output = BPF.ar(grain, centreFrequency.lag3(1*urLag), rq.lag3(1*urLag))*control;

	Out.ar(busOut, Limiter.ar(FreeVerb.ar(bandpass*levelOut.lag3(0.1*urLag), mix.lag3(2*urLag), room.lag3(2))*control, 0.7)*(1-granularized.lag3(0.1*urLag)));
	Out.ar(busOut, Limiter.ar(FreeVerb.ar(output*levelOut.lag3(0.1*urLag), mix.lag3(2*urLag), room.lag3(2)), 0.7)*granularized.lag3(0.1*urLag));
}).add;
)


/*
███╗   ███╗██╗██████╗ ██╗     ██████╗ ██████╗ ███╗   ██╗████████╗██████╗  ██████╗ ██╗     ███████╗
████╗ ████║██║██╔══██╗██║    ██╔════╝██╔═══██╗████╗  ██║╚══██╔══╝██╔══██╗██╔═══██╗██║     ██╔════╝
██╔████╔██║██║██║  ██║██║    ██║     ██║   ██║██╔██╗ ██║   ██║   ██████╔╝██║   ██║██║     ███████╗
██║╚██╔╝██║██║██║  ██║██║    ██║     ██║   ██║██║╚██╗██║   ██║   ██╔══██╗██║   ██║██║     ╚════██║
██║ ╚═╝ ██║██║██████╔╝██║    ╚██████╗╚██████╔╝██║ ╚████║   ██║   ██║  ██║╚██████╔╝███████╗███████║
╚═╝     ╚═╝╚═╝╚═════╝ ╚═╝     ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚══════╝

*/

// I use the Novation Launch Control XL
// Each  column on the controller controls a single cone.
// The controls are:
//       -- Fader: global output level of the cone
//       -- Knob1: amplitude of fundamental
//       -- Knob2: amplitude of first freq shift
//       -- Knob3: amplitude of second freq shift
//
// In addition to that, there are only TWO buttons on the controller that are used to trigger needed changes of basically all the parameters.
// This two cues are used: 1) before the beginning of the piece; 2) at bar 213 in the score.
// In this MIDI mapping, the buttons are channels 91 and 92.

(
~numCones = 8;
~numCones.do({ |n|
	ControlSpec.specs[(\levelOut++n).asSymbol] = ControlSpec(0, 2.0, 'lin', 0.00001, 0); //0 2
	ControlSpec.specs[(\mulZero++n).asSymbol] = ControlSpec(0, 1.0, 'lin', 0.00001, 0); //70, 1e4
	ControlSpec.specs[(\mulFirst++n).asSymbol] = ControlSpec(0, 1.0, 'lin', 0.00001, 0); //70, 1e4
	ControlSpec.specs[(\mulSecond++n).asSymbol] = ControlSpec(0, 1.0, 'lin', 0.00001, 0); //70, 1e4
});

~levelOut = Array.fill(~numCones, {Bus.control(s, 1).set(0)});
~mulZero = Array.fill(~numCones, {Bus.control(s, 1).set(0)});
~mulFirst = Array.fill(~numCones, {Bus.control(s, 1).set(0)});
~mulSecond = Array.fill(~numCones, {Bus.control(s, 1).set(0)});

MIDIIn.connectAll;

//Just the CC of the novation MIDI control
~row1 = (13..20);
~row2 = (29..36);
~row3 = (49..56);
~row4 = (77..84);

~numCones.do({|n|
	MIDIdef.cc((\levelOut++n).asSymbol, { arg v;
		"levelOut cone_% :".format(n).post;
		~levelOut[n].set(ControlSpec.specs[(\levelOut++n).asSymbol].map(v/127).postln)}, ~row4[n]);
	MIDIdef.cc((\mul0++n).asSymbol, { arg v;
		"Mul0 cone_% :".format(n).post;
		~mulZero[n].set(ControlSpec.specs[(\mulZero++n).asSymbol].map(v/127).postln)}, ~row3[n]);
	MIDIdef.cc((\mul1++n).asSymbol, { arg v;
		"Mul1 cone_% :".format(n).post;
		~mulFirst[n].set(ControlSpec.specs[(\mulFirst++n).asSymbol].map(v/127).postln)}, ~row2[n]);
	MIDIdef.cc((\mul2++n).asSymbol, { arg v;
		"Mul2 cone_% :".format(n).post;
		~mulSecond[n].set(ControlSpec.specs[(\mulSecond++n).asSymbol].map(v/127).postln)}, ~row1[n]);
});


MIDIdef.cc(\button1, {
	"Button1".postln;
	~cones[7].set(\gain, 1, \rinf, 40, \rsup, 120, \rq, 0.7, \impulseFrequency, 321, \impuls, 1, \durGrain, 0.027, \mix, 0.7, \granularized, 0.5, \filtered, 1, \lfFreq, 0.1, \delay, 1.5, \bandwidth, 10, \freqShift1, 200, \freqShift2, 2060);
	~cones[6].set(\gain, 1, \rinf, 40, \rsup, 120, \rq, 0.7, \impulseFrequency, 321, \impuls, 1, \durGrain, 0.027, \mix, 0.7, \granularized, 0.5, \filtered, 1, \lfFreq, 0.1, \delay, 1.5, \bandwidth, 10, \freqShift1, 200, \freqShift2, 2050);
	~cones[5].set(\gain, 1, \rinf, 200, \rsup, 400, \rq, 0.5, \impulseFrequency, 321, \impuls, 1, \durGrain, 0.027, \mix, 0.4, \granularized, 0.3, \filtered, 1, \lfFreq, 0.1, \delay, 1.5, \bandwidth, 30, \freqShift1, 2060, \freqShift2, 2100);
	~cones[4].set(\gain, 1, \rinf, 200, \rsup, 400, \rq, 0.5, \impulseFrequency, 321, \impuls, 1, \durGrain, 0.027, \mix, 0.4, \granularized, 0.3, \filtered, 1, \lfFreq, 0.1, \delay, 1.5, \bandwidth, 30, \freqShift1, 2066, \freqShift2, 2110);
	~cones[3].set(\gain, 1, \rinf, 260, \rsup, 260*4, \rq, 0.1, \centreFrequency, 400, \impulseFrequency, 321, \impuls, 1, \durGrain, 0.027, \mix, 0.4, \granularized, 0.3, \filtered, 1, \lfFreq, 0.1, \delay, 1.5, \bandwidth, 12, \freqShift1, 100, \freqShift2, 170);
	~cones[2].set(\gain, 1, \rinf, 260, \rsup, 260*4, \rq, 0.1, \centreFrequency, 300, \impulseFrequency, 321, \impuls, 1, \durGrain, 0.027, \mix, 0.4, \granularized, 0.3, \filtered, 1, \lfFreq, 0.1, \delay, 1.5, \bandwidth, 20, \freqShift1, 150, \freqShift2, 210);
	~cones[1].set(\gain, 1, \rinf, 400, \rsup, 3000, \rq, 0.1, \impulseFrequency, 321, \impuls, 1, \durGrain, 0.027, \mix, 0.4, \granularized, 0.2, \filtered, 1, \lfFreq, 10, \delay, 1.5, \bandwidth, 10, \freqShift1, 200, \freqShift2, 2050);
	~cones[0].set(\gain, 1, \rinf, 400, \rsup, 3000, \rq, 0.1, \impulseFrequency, 321, \impuls, 1, \durGrain, 0.027, \mix, 0.4, \granularized, 0.2, \filtered, 1, \lfFreq, 10, \delay, 1.5, \bandwidth, 10, \freqShift1, 200, \freqShift2, 2050);
}, 91);


MIDIdef.cc(\button2, {
	"Button2".postln;
	~cones[7].set(\gain, 1, \levelOut, 1, \rinf, 40, \rsup, 100, \rq, 0.7, \wipe, 0.05, \impulseFrequency, 321, \durGrain, 0.033, \mix, 0.2, \granularized, 0.5, \filtered, 1, \lfFreq, 0.1, \delay, 1.5, \bandwidth, 10, \freqShift1, 200, \freqShift2, 2050, \mul0, 0.6, \mul1, 0.3, \mul2, 0);
	~cones[6].set(\gain, 1, \levelOut, 1, \rinf, 40, \rsup, 100, \rq, 0.7, \wipe, 0.05, \impulseFrequency, 321, \durGrain, 0.033, \mix, 0.2, \granularized, 0.5, \filtered, 1, \lfFreq, 0.1, \delay, 1.5, \bandwidth, 10, \freqShift1, 210, \freqShift2, 1850, \mul0, 0.6, \mul1, 0.3, \mul2, 0);
	~cones[5].set(\gain, 1, \levelOut, 1.5, \rinf, 200, \rsup, 400, \rq, 1, \wipe, 0.1, \impulseFrequency, 241, \durGrain, 0.037, \mix, 0.2, \granularized, 0, \filtered, 1, \lfFreq, 0.1, \delay, 1.5, \bandwidth, 10, \freqShift1, 200, \freqShift2, 400, \mul0, 1, \mul1, 0.5, \mul2, 0.5);
	~cones[4].set(\gain, 1, \levelOut, 1.5, \rinf, 200, \rsup, 400, \rq, 1, \wipe, 0.01, \impulseFrequency, 321, \durGrain, 0.027, \mix, 0.2, \granularized, 0, \filtered, 1, \lfFreq, 0.1, \delay, 1.5, \bandwidth, 10, \freqShift1, 300, \freqShift2, 500, \mul0, 1, \mul1, 0.5, \mul2, 0.5);
	~cones[3].set(\busIn, 2, \busOut, 3, \gain, 1, \levelOut, 1, \rinf, 260, \rsup, 260*3, \rq, 0.1, \centreFrequency, 520, \impulseFrequency, 321, \durGrain, 0.027, \mix, 0.4, \granularized, 0.2, \filtered, 1, \lfFreq, 0.1, \delay, 0.11, \bandwidth, 50, \freqShift1, 50, \freqShift2, 60, \mul0, 0.8, \mul1, 1, \mul2, 1);
	~cones[2].set(\busIn, 3, \busOut, 2, \gain, 1, \levelOut, 1, \rinf, 260, \rsup, 260*3, \rq, 0.1, \centreFrequency, 520, \impulseFrequency, 321, \durGrain, 0.027, \mix, 0.4, \granularized, 0.2, \filtered, 1, \lfFreq, 0.1, \delay, 0.1, \bandwidth, 50, \freqShift1, 56, \freqShift2, 68, \mul0, 0.8, \mul1, 1, \mul2, 1);
	~cones[1].set(\busIn, 0, \busOut, 1, \gain, 1, \levelOut, 1, \rinf, 300, \rsup, 300*3, \rq, 0.1, \centreFrequency, 600, \impulseFrequency, 321, \durGrain, 0.027, \mix, 0.4, \granularized, 0.2, \filtered, 1, \lfFreq, 0.1, \delay, 0.1, \bandwidth, 50, \freqShift1, 24, \freqShift2, 48, \mul0, 0.8, \mul1, 1, \mul2, 1);
	~cones[0].set(\busIn, 1, \busOut, 0, \gain, 1, \levelOut, 1, \rinf, 300, \rsup, 300*3, \rq, 0.1, \centreFrequency, 600, \impulseFrequency, 321, \durGrain, 0.027, \mix, 0.4, \granularized, 0.2, \filtered, 1, \lfFreq, 0.1, \delay, 0.1, \bandwidth, 50, \freqShift1, 52, \freqShift2, 72, \mul0, 0.8, \mul1, 1, \mul2, 1);
}, 92);

)

// In case needed:
// MIDIdef.freeAll; // free all registered MIDIdefs


/*
     ██╗ █████╗ ███╗   ███╗███╗   ███╗    ██████╗ ███████╗██╗     ██╗
     ██║██╔══██╗████╗ ████║████╗ ████║    ██╔══██╗██╔════╝██║     ██║
     ██║███████║██╔████╔██║██╔████╔██║    ██████╔╝█████╗  ██║     ██║
██   ██║██╔══██║██║╚██╔╝██║██║╚██╔╝██║    ██╔══██╗██╔══╝  ██║     ██║
╚█████╔╝██║  ██║██║ ╚═╝ ██║██║ ╚═╝ ██║    ██████╔╝███████╗███████╗███████╗
 ╚════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚═╝     ╚═╝    ╚═════╝ ╚══════╝╚══════╝╚══════╝

*/

// Here is where the pain starts:

(
~numCones = 8;
~cones = Array.fill(~numCones, 0); //array of 8 cones
~busIn = (0..7);
~busOut = (0..7);
//
~numCones.do({|n|
	~cones[n] = Synth(\learnSuffering, [
		\busIn, ~busIn[n],
		\busOut, ~busOut[n],
		\gain, 0,
		\levelOut, ~levelOut[n].asMap,
		\mul0, 1,
		\mul1, ~mulFirst[n].asMap,
		\mul2, ~mulFirst[n].asMap,
		\impuls, 1, // this is the parameter to decide if regular impulses (1 - IMpulse.ar) or not (0 - Dust.ar)
		\impulseFrequency, 1,
		\durGrain, 0.01,
		\rinf, 40,
		\rsup, 100,
		\rq, 0.1,
		\filtered, 1,
		\granularized, 1,
		\mix, 0.1,
		\urLag, 1 ]);
});
)

// EOF