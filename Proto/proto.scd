
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
    q.freqs = #[ 110, 150, 250, 350, 500, 630, 800, 1000, 1300, 1600, 2000, 2600, 3500, 5000, 8000, 10000 ];

    q.init = {|self|
        self.vocoder();
    };

    q.envelope_follower = {|self, input, in_select=0, env_decay_time=0.04|
        var encoder, enc_even, enc_odd;
        encoder = q.freqs.collect {|freq| 
            Amplitude.ar(10 * BPF.ar(input, freq, q.rq), 0.05) 
        };
        enc_even = encoder.select {|x,i| i.even };
        enc_odd  = encoder.select {|x,i| i.odd  };
        encoder  = Select.ar(in_select, [ encoder, enc_even, enc_odd ]);
        encoder;
    };

    q.decoder = {|self, input, in_select=0, out_select=0|
        var envs = self.envelope_follower(input, in_select);
        // these should be args..
        var band_amps = q.freqs.size.collect {|i| NamedControl.ar("band%_amp".format(i+1).asSymbol, 1, 0.1) }; // lag time?
        var decoder, dec_even, dec_odd;
        // TODO: factor out band_amps
        decoder  = [ q.freqs, band_amps ].flopWith {|freq, amp| 
            amp * 10 * BPF.ar(input, freq, q.rq) 
        };
        dec_even = decoder.select {|x,i| i.even };
        dec_odd  = decoder.select {|x,i| i.odd  };
        decoder  = Select.ar(out_select, [ decoder, dec_even, dec_odd ]);
        decoder;
    };

    q.eq = {|self, input, in_select=0, out_select=0|
        self.decoder(input, in_select, out_select).sum;
    };

    q.vocoder = {|self, modulator, carrier, in_select=0, out_select=0|
        var envs = self.envelope_follower(modulator, in_select);
        var eq   = self.decoder(carrier, out_select);
        var sig = eq * envs;
        sig.sum;
    };

    q.comb = {|self, input|
        var eq = self.eq(input);
        eq.sum;
    };

s.waitForBoot {
    var buf = ~speech.choose;

    ~speech ?? {
        ~speech = AudioFileLib("~/audio/speech");
        ~speech = ~speech.libraryWithBuffers;
        s.sync;
    };

    buf = ~speech['speech'].choose;

    play {
        var mod = PlayBuf.ar(buf.numChannels, buf, BufRateScale.kr(buf), loop:1);
        // var vocoder = q.vocoder(mod, Saw.ar(110));
        // [ 8*q.vocoder(mod, Saw.ar(55)), 0.1*mod ];
        // [ 8*q.vocoder(mod, Saw.ar(55)), 8*q.vocoder(mod, Saw.ar(55*1.5)) ];
        [ q.vocoder(mod, Saw.ar(55, 0.5)), q.vocoder(mod, Saw.ar(55 * 1.5, 0.5)) ];
    };
};            
)


s.makeWindow
s.meter;



14.reciprocal.sqrt

(

    SynthDef(\psp_m296, { 
        |
            // input
            in_select        = 1, // 0=even, 1=all, 2=odd
            // attenuator
            att_out_select = 1, // 0=even, 1=all, 2=odd
            // comb
            comb_out_select  = 0, // 0=even, 1=odd
            // programmable
            prog_out_select  = 0, // 0=even, 1=all, 2=odd
            prog_ctl_freq    = 1, // multiplier
            prog_ctl_width   = 1, // multiplier
            // output
            prog_on          = 0,
            att_on           = 0,
            comb_on          = 0,
            // misc
            env_decay_time   = 0.04,
            gate             = 1,
            amp              = 0.1,
            mod_in,
            car_in,
            b, // just for test
            out
        |
        var encoder, decoder;
        var enc_even, enc_odd, dec_even, dec_odd;
        var programmable, attenuator, comb, output;

        // var modulator = In.ar(mod_in,2);
        // var carrier = In.ar(car_in,2);
        var carrier = Saw.ar(55); // this should be an arg too
        var modulator = 3 * PlayBuf.ar(1, b, 1 * BufRateScale.kr(b), loop:1); // test
        // freqs from buchla programmable spectral processsor model 296
        var freqs = #[ 110, 150, 250, 350, 500, 630, 800, 1000, 1300, 1600, 2000, 2600, 3500, 5000, 8000, 10000 ];
        var rq = 0.04;
        // amp controls for each band
        var band_amps = freqs.size.collect {|i| NamedControl.ar("band%_amp".format(i+1).asSymbol, 1, 0.1) }; // lag time?
        // compress input signal?
        // modulator = Compander.ar(modulator, modulator, -12.dbamp, 1, 1/8);
        // modulator = Limiter.ar(5 * modulator);
        // encoder
        encoder = freqs.collect {|freq| 
            Amplitude.ar(10 * BPF.ar(modulator, freq, rq), 0.05, env_decay_time) 
        };
        enc_even = encoder.select {|x,i| i.even };
        enc_odd  = encoder.select {|x,i| i.odd  };
        encoder  = Select.ar(in_select, [ enc_even, encoder, enc_odd ]);
        // decode
        decoder  = [ freqs, band_amps ].flopWith {|freq, amp| 
            amp * 10 * BPF.ar(carrier, freq, rq) 
        };
        dec_even = decoder.select {|x,i| i.even };
        dec_odd  = decoder.select {|x,i| i.odd  };
        // output select
        programmable = Select.ar(prog_out_select, [ dec_even, decoder, dec_odd ]);
        // vocoder
        programmable = encoder * programmable;
        attenuator = Select.ar(att_out_select, [ dec_even, decoder, dec_odd ]);
        comb = Select.ar(comb_out_select, [ dec_even, dec_odd ]);
        output = [ prog_on * programmable, att_on * attenuator, comb_on * comb ].mean;
        Out.ar(out, amp * output.sum ! 2);
    }).add;
)


