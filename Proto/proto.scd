
PSP296(\vocoder, modulator:mod, carrier:car, band0_amp:0.5);

a = [\eq, \input, x, {|i| [ "band%_amp".format(i).asSymbol, rrand(0.1, 1.0) ] }.dup(16) ].flat;

PSP296.eq(*a);
PSP296.vocoder
PSP296.comb


// TODO
//
// Split functionality accross different creation methods.
//  - It would be nice to just use 'env' to get the envelope follower output
//  - By splitting, we can mix freely between sources e.g. comb, vocoder, eq
//  - We can also use different args for each creation method, vocoder need mod, car but eq don't.
//  
//  Should we auto-generate args for band%_amp? Maybe an option.. or instance method?

PSP296.vocoder(*args).autoGenerateControls;
PSP296.generateControls("band_"); // band_

PSP296.vocoder()
PSP296.envelope_follower();

PSP296.gui(~synth);



(
    q = q ? ();

    q.rq = 0.03;
    q.env_decay_time = 0.04;

    // freqs from buchla programmable spectral processsor model 296
    // q.freqs = #[ 110, 150, 250, 350, 500, 630, 800, 1000, 1300, 1600, 2000, 2600, 3500, 5000, 8000, 10000 ];

    // internal use only
    q.signal_input = {|self, freqs, input, in_select=0|
        var bands, even, odd;
        bands = freqs.collect {|freq| 
            10 * BPF.ar(input, freq, q.rq)
        };
        even  = bands.select {|x,i| i.even };
        odd   = bands.select {|x,i| i.odd  };
        bands = Select.ar(in_select, [ bands, even, odd ]);
        bands;
    };

    // internal use only
    q.decoder = {|self, freqs, amps, input, in_select=0, out_select=0|
        var decoder, dec_even, dec_odd;
        decoder = [ freqs, amps ].flopWith {|freq, amp| 
            amp * 10 * BPF.ar(input, freq, q.rq) 
        };
        dec_even = decoder.select {|x,i| i.even };
        dec_odd  = decoder.select {|x,i| i.odd  };
        decoder  = Select.ar(out_select, [ decoder, dec_even, dec_odd ]);
        decoder;
    };

    q.envelope_follower = {|self, freqs, input, in_select=0, env_decay_time=0.04|
        var signal  = self.signal_input(freqs, input, in_select);
        var encoder = signal.collect {|sig|
            Amplitude.ar(sig, 0.01, env_decay_time); 
        };
        encoder;
    };

    q.attenuator = {|self, freqs, amps, input, in_select=0, out_select=0|
        var bands, even, odd;
        var signal = self.signal_input(freqs, input, in_select);
        bands = [ signal, amps ].flopWith {|sig, amp| sig * amp };
        even  = bands.select {|x,i| i.even };
        odd   = bands.select {|x,i| i.odd  };
        bands = Select.ar(out_select, [ bands, even, odd ]);
        bands.sum * freqs.size.reciprocal.sqrt;
    };

    q.vocoder = {|self, freqs, amps, modulator, carrier, in_select=0, out_select=0|
        var envs = self.envelope_follower(freqs, modulator, in_select);
        var decode = self.decoder(freqs, amps, carrier, out_select);
        (decode * envs).sum * freqs.size.reciprocal.sqrt;
    };

    q.comb = {|self, freqs, input, in_select=0, out_select=0|
        var bands, even, odd;
        bands = self.signal_input(freqs, input, in_select);
        even  = bands.select {|x,i| i.even };
        odd   = bands.select {|x,i| i.odd  };
        bands = Select.ar(out_select, [ even, odd ]);
        bands.sum * freqs.size.reciprocal.sqrt;
    };

    s.waitForBoot {
        var buf;

        ~speech ?? {
            ~speech = AudioFileLib("~/audio/speech");
            ~speech = ~speech.libraryWithBuffers;
            s.sync;
        };

        buf = ~speech['speech'][3];

        {
            var freqs = #[ 110, 150, 250, 350, 500, 630, 800, 1000, 1300, 1600, 2000, 2600, 3500, 5000, 8000, 10000 ];
            // var freqs = { exprand(55.0, 1000.0) }.dup(16);
            var amps  = { 1 }.dup(freqs.size);
            var envs, mod   = PlayBuf.ar(buf.numChannels, buf, BufRateScale.kr(buf), loop:1);
            // test

            var attenuator, vocoder, combs, pm;
            vocoder = [ 
                q.vocoder(freqs, amps, mod, Saw.ar(55)),
                q.vocoder(freqs, amps, mod, Saw.ar(55 * 1.5)) 
            ];

            // 2.collect {|i| q.attenuator(freqs, amps, mod, 0, 1 + i) };
            // 2.collect {|i| q.comb(freqs, mod, i) };

            // envs = q.envelope_follower(freqs, mod);
            // envs.size.postln;
            // freqs.size.postln;
            // pm = Splay.ar(
            //     SinOsc.ar(
            //         55,
            //         // pi * SinOsc.ar({|i| exprand(110.0, 10000.0) }.dup(freqs.size))
            //         pi * SinOsc.ar({|i| 1 * 55 * (i+1) }.dup(freqs.size))
            //     ) * envs;
            // ).mean;

            // vocoder + (0.5 * pm ! 2);

        }.play;
    };            
)

Quarks.gui
~speech['speech'][3]

s.makeWindow
s.meter;
s.plotTree

x = `[ {rrand(440,880)}.dup(8), {rrand(0.1,0.5)}.dup(8) ]
x.multichannelExpandRef(2)

Klank


(
    var freqs = [ 200, 400, 800, 1000 ];
    var amps  = (1..freqs.size).reciprocal;
    PSP296.vocoder(`[ freqs, amps ], mod, car, in_select, out_select);
)

s.makeWindow
s.meter;


f = {|foo, bar ... band_amps|
    // [ foo, bar, band_amps ];
    band_amps.unbubble.collect {|amp|
        amp.postln;
    };
};

f.(1, 2, (1..10))



14.reciprocal.sqrt


2 ** 18
r = Buffer.alloc(s, 2**18, 2);
r.write("~/Desktop/vocoder_test.wav".standardizePath, "wav", "int24", 0, 0, true);
r.close;

SynthDef("help-Diskout", {arg bufnum;
    DiskOut.ar(bufnum, In.ar(12,2));
}).play(args:[\bufnum, r]);



(88..99).do(_.even);

x = ar(SinOsc);

play { x * 0.1 };



///////////////////////////////////////////////////////////////////////////

'F1'.asNote.midicps

x.set(\freq, 'E1'.asNote.midicps);
x.set(\freq, 'F1'.asNote.midicps);

x.set(\freq, 'c'.asNote.midicps);

x.set(\freq, 'Eb1'.asNote.midicps);
x.set(\freq, 'C'.asNote.midicps);
x.set(\freq, 'G'.asNote.midicps);
x.set(\freq, 'Bb1'.asNote.midicps);

'c'.asNote.midicps

s.boot;
(
    x = play {|freq=38.8908|
        var x, o = Saw.ar(freq*[0.984,1,1.001]*[1,1,2]).mean;
        o = o + SinOsc.ar(freq*[1,1],0,1).mean;
        o = o + sin(1.5*o);
        o = o + BPF.ar(o, 2*freq);
        x = Hilbert.ar(HPF.ar(o,1*freq))[1];
        o = RLPF.ar(o, (4*(1.5*freq)).clip(20,20000), 0.3);
        4.do { x = AllpassN.ar(OnePole.ar(x,0.8), 1, {Rand(1e-4,0.01)}.dup, 1) };
        o = o + x;
        o = Compander.ar(o, LFDNoise3.ar(24), -18.dbamp, 1.0, 1/10, 0.1, 0.1);
        o = RLPF.ar(o, 10000);
        o = GVerb.ar(o*0.5, 85, 15); // 85
        o = BLowShelf.ar(o, 90, 0.1, -4);
        // o = x;
        o = LeakDC.ar(o);
        o = Limiter.ar(o);
        // o = Normalizer.ar(o);
        // o = Limiter.ar(o);
        // o * 0.5 ! 2;
        o * 0.5;
    }
)

(1.5*55) * 64

16*2
s.meter;


{ Hilbert.ar(SinOsc.ar(880)) }.plot
