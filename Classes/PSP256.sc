PSP256 {

    classvar rq = 0.03;

    // internal use only
    *signal_input {|freqs, input, in_select=0|
        var bands, even, odd;
        bands = freqs.collect {|freq| 
            10 * BPF.ar(input, freq, rq)
        };
        even  = bands.select {|x,i| i.even };
        odd   = bands.select {|x,i| i.odd  };
        bands = Select.ar(in_select, [ bands, even, odd ]);
        ^bands;
    }

    // internal use only
    *decoder {|freqs, amps, input, in_select=0, out_select=0|
        var decoder, dec_even, dec_odd;
        decoder = [ freqs, amps ].flopWith {|freq, amp| 
            amp * 10 * BPF.ar(input, freq, rq) 
        };
        dec_even = decoder.select {|x,i| i.even };
        dec_odd  = decoder.select {|x,i| i.odd  };
        decoder  = Select.ar(out_select, [ decoder, dec_even, dec_odd ]);
        ^decoder;
    }

    *attenuator {|freqs, amps, input, in_select=0, out_select=0|
        var bands, even, odd;
        var signal = this.signal_input(freqs, input, in_select);
        bands = [ signal, amps ].flopWith {|sig, amp| sig * amp };
        even  = bands.select {|x,i| i.even };
        odd   = bands.select {|x,i| i.odd  };
        bands = Select.ar(out_select, [ bands, even, odd ]);
        ^bands.sum * freqs.size.reciprocal.sqrt;
    }

    *vocoder {|freqs, amps, modulator, carrier, in_select=0, out_select=0|
        var envs   = this.envelope_follower(freqs, modulator, in_select);
        var decode = this.decoder(freqs, amps, carrier, out_select);
        ^(decode * envs).sum * freqs.size.reciprocal.sqrt;
    }

    *comb {|freqs, input, in_select=0, out_select=0|
        var bands, even, odd;
        bands = this.signal_input(freqs, input, in_select);
        even  = bands.select {|x,i| i.even };
        odd   = bands.select {|x,i| i.odd  };
        bands = Select.ar(out_select, [ even, odd ]);
        ^bands.sum * freqs.size.reciprocal.sqrt;
    }

    *envelope_follower {|freqs, input, in_select=0, env_decay_time=0.04|
        var signal  = this.signal_input(freqs, input, in_select);
        var encoder = signal.collect {|sig|
            Amplitude.ar(sig, 0.01, env_decay_time); 
        };
        ^encoder;
    }
}
