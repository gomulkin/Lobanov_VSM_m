/* 

Lobanov Glottal Source Model 
as described in: 
Lobanov, B. M. PHD Thesis. Minsk, 1983.

Implemented in Chuck by Danila Gomulkin, 2017

Mouse controls:
<<< (left)    - pitch down
>>> (right)   - pitch up
^^^ (up)      - relative pulse duration up ("skvazhnost")
VVV (down)    - relative pulse duration down
left  button  - sound ON/OFF
right button  - quit the program

*/


// headline
<<<"******************************">>>;
<<<"          NEW SHRED           ">>>;
<<<"******************************">>>;

//sound chain
Impulse pop => Gain out => Gain out1 => dac;

// variables for OSC/Hid/Serial control:

// Pitch (Hz)
100.0 => float pitch => float pitchNew;
0.95 => float pitchSmooth; // smoothening ratio

// T3 (duration of Force b) ratio to T0:
0.7 => float bForce => float bForceNew;
0.95 => float bForceSmooth; // smoothening ratio

// T1 (duration of Force b) ratio to T3:
0.3 => float aForce => float aForceNew;
0.95 => float aForceSmooth; // smoothening ratio

// smoothening function
fun void smoothStuff(){
    while (true){
        pitch*pitchSmooth + pitchNew*(1-pitchSmooth) => pitch;
        bForce*bForceSmooth + bForceNew*(1-bForceSmooth) => bForce;
        aForce*aForceSmooth + aForceNew*(1-aForceSmooth) => aForce;
        //out2.gain()*volumeSmooth + volume*(1-volumeSmooth) => out2.gain;
        20::ms => now;
    }
}

// declare arrays
float popGain0[10000];
float popGain1[10000];
float popGain2[10000];

//variables
int T0, T3, T1;
float Pitch;

function void glottal(){       
    // SET PITCH (HZ)
    if (pitch!= Pitch){
    pitch => Pitch; 

    Std.ftoi(44100/Pitch) => T0; // duration of the cycle (samples, Fs=44100 Hz)
    Std.ftoi(T0*bForce) => T3; // duration for Force B (samples) relative to T0
    1.0/(T0*2) => out.gain; // scaling OUT gain DOWN (to be improved)
    Std.ftoi(T3*aForce) => T1; // duration for Force A (samples) relative to T0

    // no clipping down to 38 Hz (T0 under 1160 samples)
    0.04 => float Force_A; // starting point fot further automatical adjusted
    -0.04 => float Force_B; // fixed value



    // fill them arrays
    for (0 => int i; i < T1+1; i++){
        Force_A => popGain0[i];
        //<<<"gain0(", i, ")", popGain0[i]>>>;
    }
    for (T1 => int i; i < T3+1; i++){
        Force_B => popGain0[i];
        //<<<"gain0(", i, ")", popGain0[i]>>>;
    }

    //integrate x2
    for (1=>int i; i < T3+1; i++){
        popGain1[i-1] + popGain0[i] => popGain1[i]; // force => velocity (1)
         //<<<"gain1(", i, ")", popGain1[i]>>>;
    }
    for (1 => int i; i < T3+1; i++){
        popGain2[i-1] + popGain1[i] => popGain2[i]; // velocity => movement (2)
         // <<<"gain2(", i, ")", popGain2[i]>>>;
    }

    // <<<"popGain2[T3]=",popGain2[T3]>>>;

    if (popGain2[T3] < 0){
        // <<<"popGain2[T3] < 0">>>;
        while (popGain2[T3] < 0){
            Force_A + 0.0001 => Force_A;
            // <<<"Force_A =", Force_A>>>;
            // fill them arrays again
            for (0 => int i; i < T1+1; i++){
                Force_A => popGain0[i];
                // <<<"gain0(", i, ")", popGain0[i]>>>;
            }
            for (T1 => int i; i < T3+1; i++){
                Force_B => popGain0[i];
                // <<<"gain0(", i, ")", popGain0[i]>>>;
            }

            //integrate two times again
            for (1=>int i; i < T3+1; i++){
                popGain1[i-1] + popGain0[i] => popGain1[i]; // force => velocity
                 // <<<"gain1(", i, ")", popGain1[i]>>>;
            }
            for (1=>int i; i < T3+1; i++){
                popGain2[i-1] + popGain1[i] => popGain2[i]; // velocity => displacement
                 // <<<"gain2(", i, ")", popGain2[i]>>>;
            }
            <<<"popGain2[T3]=",popGain2[T3]>>>;
        }
    }

    if (popGain2[T3] > 1){
        // <<< "popGain2[T3] > 1" >>>;
        while (popGain2[T3] > 1 ){
            Force_A - 0.0001 => Force_A;
            // <<<"Force_A =", Force_A>>>;
            // fill them arrays again
            for (0 => int i; i < T1+1; i++){
                Force_A => popGain0[i];
                // <<<"gain0(", i, ")", popGain0[i]>>>;
            }
            for (T1 => int i; i < T3+1; i++){
                Force_B => popGain0[i];
                // <<<"gain0(", i, ")", popGain0[i]>>>;
            }

            //integrate two times again
            for (1=>int i; i < T3+1; i++){
                popGain1[i-1] + popGain0[i] => popGain1[i]; // force => velocity
                 // <<<"gain1(", i, ")", popGain1[i]>>>;
            }
            for (1=>int i; i < T3+1; i++){
                popGain2[i-1] + popGain1[i] => popGain2[i]; // velocity => displacement
                 // <<<"gain2(", i, ")", popGain2[i]>>>;
            }
            <<<"popGain2[T3]=",popGain2[T3]>>>;
        }
    }
    else{
    }

    // print final gain values:
    /*
    for (1 => int i; i < T3+1; i++){
        <<<"gain2(", i, ")", popGain2[i]>>>;
    }
    */
    <<<"******************************">>>;

    //<<<"T0 =", T0, "(cycle) / T3 =", T3, "(open) / T1 =", T1, "(up)">>>;
    <<<"Pitch =", Pitch, "Hz, Fs = 44100 Hz">>>;
    <<<"T0 =", T0, "sm / T3 =", T3, "sm / T1 =", T1, "sm">>>;
    <<<"Force_A = ", Force_A, "(calculated)">>>;
    <<<"Force_B =", Force_B, "(set)">>>;
    <<<"popGain2[T3]=", popGain2[T3]>>>;

    <<<"******************************">>>;
}
    }

//play
function void play(){
    while(true){
        glottal();
        for(0 => int i; i < T0+1; i++){
            popGain2[i] => pop.gain;
            1 => pop.next;
            1::samp => now;
            if (pop.last() > 20000){ // just in case
                <<<"Too loud!">>>;
                break;
            }
        }
    }
}

// MOUSE CONTROL*************************************************
// from mouse-fm.ck by Spencer Salazar

// which mouse
0 => int device;
// get from command line
if( me.args() ) me.arg(0) => Std.atoi => device;

// variables
100.0 => float a0;
0.7 => float a1;
0.3 => float a2;
1 => int count;

// start things
//set( base, a0, a1, a2 );

// hid objects
Hid hi;
HidMsg msg;

// try
if( !hi.openMouse( device ) ) me.exit();
<<< "mouse '" + hi.name() + "' ready...", "" >>>;

// END OF MOUSE CONTROL*****************************************


function void mouseControl(){
    // infinite time loop
    while( true )
    {
        // wait on event
        hi => now;
        // loop over messages
        while( hi.recv(msg) ){
            if( msg.isMouseMotion() ){
                msg.deltaX*.2 + a0 => a0;
                -msg.deltaY*.001 + a1 => a1;
                a0 => pitchNew;
                a1 => bForceNew;
                
                //<<<"pitchNew =", pitchNew>>>;
            }

            else if( msg.isButtonDown() & msg.which==0){
                //msg.which => base;
                count++;
                if( count%2 == 1 ){
                    1 => out1.gain;
                    <<<"sound ON">>>;
                }
                else {
                    0 => out1.gain;
                    <<<"sound OFF">>>;
                }
            }
            else if( msg.isButtonDown() & msg.which==1){
                Machine.remove(1);
                <<<"right buttom down!!">>>;
            }
        }
        0.2::second=>now;
    }
}

spork ~ mouseControl();
spork ~ smoothStuff();

play();

// CONTROLS
