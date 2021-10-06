(
~fftsize = 2048;

s.waitForBoot {

    {
        var ir, irbuffer, bufsize;

        // // MONO ONLY
        // pre-existing impulse response sound files
        // (could also use any general soundfile too for cross-synthesis effects)
		irbuffer = Buffer.read(s, "/Users/joes/Code/Supercollider/sc-feedback-buffer/sounds/cave_irMono.wav");

        s.sync;

        bufsize = PartConv.calcBufSize(~fftsize, irbuffer);

        // ~numpartitions= PartConv.calcNumPartitions(~fftsize, irbuffer);

        ~irspectrum = Buffer.alloc(s, bufsize, 1);
        ~irspectrum.preparePartConv(irbuffer, ~fftsize);

        s.sync;

        irbuffer.free; // don't need time domain data anymore, just needed spectral version
    }.fork;

}
)

~srcBuffer = Buffer.read(s, "/Users/joes/Code/Supercollider/sc-feedback-buffer/sounds/consynthMono.wav");


(
SynthDef(\helpTap, { |out, bufnum|

    var source, sourceRev, indx, capture;

	indx = Phasor.ar(0, 1, 0, BufFrames.ir(bufnum), 1);
	source = BufRd.ar(1, ~srcBuffer, indx);
	sourceRev = source + PartConv.ar(source, ~fftsize, ~irspectrum.bufnum, 0.05);
    capture = BufWr.ar(Limiter.ar(sourceRev, 0.7, 0.05), bufnum, indx);

	Out.ar(out, [sourceRev, sourceRev]); // multichannel expansion, so one tap each ear
}).add;
)

// { BufRd.ar(1, b, Phasor.ar(0, BufRateScale.kr(b), 0, BufFrames.kr(b))) }.play;

x = Synth(\helpTap, [\bufnum, ~srcBuffer]);

x.free;