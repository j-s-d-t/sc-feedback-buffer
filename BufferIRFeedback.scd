(
~fftsize = 2048;

s.waitForBoot {

    {
        var ir, irbuffer, bufsize;

        // // MONO ONLY
        // pre-existing impulse response sound files
        // (could also use any general soundfile too for cross-synthesis effects)
		irbuffer = Buffer.read(s, thisProcess.nowExecutingPath.dirname +/+ "sounds/ConradPrebysConcertHallSeatF111.wav");

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

~srcBuffer = Buffer.read(s, thisProcess.nowExecutingPath.dirname +/+ "sounds/consynthMono.wav");

(
SynthDef(\helpTap, { |out, bufnum|

    var source, sourceRev, indx, capture, sourceOut;

	indx = Phasor.ar(0, 1, 0, BufFrames.ir(bufnum), 1);
	source = BufRd.ar(1, ~srcBuffer, indx);
	sourceRev = source + PartConv.ar(source, ~fftsize, ~irspectrum.bufnum, 0.05);
    capture = BufWr.ar(Limiter.ar(sourceRev, 0.5, 0.1), bufnum, indx);
	sourceOut = sourceRev * 0.2;
	Out.ar(out, [sourceOut, sourceOut]); // multichannel expansion, so one tap each ear
}).add;
)

// { BufRd.ar(1, b, Phasor.ar(0, BufRateScale.kr(b), 0, BufFrames.kr(b))) }.play;

 x = Synth(\helpTap, [\bufnum, ~srcBuffer.bufnum]);

x.free;