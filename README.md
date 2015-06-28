#NXVoc

Under development

## TODO

Write documentation

## Example usage

```
s.boot;

b = Buffer.read(s, Platform.resourceDir +/+ "sounds/a11wlk01.wav");

// Vocoder
(
x = {|buf, in_select=0, out_select=0|
    var mod, car, vocoder;
    var freqs, amps;
    freqs = #[ 110, 150, 250, 350, 500, 630, 800, 1000, 1300, 1600, 2000, 2600, 3500, 5000, 8000, 10000 ];
    amps  = { 1 }.dup(freqs.size);
    mod = PlayBuf.ar(buf.numChannels, buf, BufRateScale.kr(buf), loop:1);
    car = Saw.ar(110 * [1,1.5]).mean;
    vocoder = NXVoc.vocoder(freqs, amps, mod, car, in_select);
    vocoder ! 2;
};
)

x.play(args:[\buf, b]);

// even input bands
x.play(args:[\buf, b, \in_select, 1]);

// odd input bands
x.play(args:[\buf, b, \in_select, 2]);


// Used as a filterbank
(
x = {|buf, in_select=0|
    var sig, car, filter_bank;
    var freqs, amps;
    freqs = #[ 110, 150, 250, 350, 500, 630, 800, 1000, 1300, 1600, 2000, 2600, 3500, 5000, 8000, 10000 ];
    amps  = { 0.5 }.dup(freqs.size);
    sig = PlayBuf.ar(buf.numChannels, buf, BufRateScale.kr(buf), loop:1);
    // modulate "out_select". (0 = all, 1 = even, 2 = odd)
    filter_bank = NXVoc.attenuator(freqs, amps, sig, in_select, LFDNoise1.kr(1/3).range(0, 2));
    0.5 * filter_bank ! 2;
};
)

x.play(args:[\buf, b]);
```
