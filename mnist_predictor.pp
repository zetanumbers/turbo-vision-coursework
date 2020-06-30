
unit mnist_predictor;
interface

{
  Automatically converted by H2Pas 1.0.0 from mnist_predictor.h
  The following command line parameters were used:
    -D
    -c
    -l
    mnist_predictor.dll
    -S
    mnist_predictor.h
}

const
  External_library='mnist_predictor.dll'; {Setup as you need}

Type
Pbyte  = ^byte;
{$IFDEF FPC}
{$PACKRECORDS C}
{$ENDIF}



procedure MnistPredictorInitialize;cdecl;external External_library name 'MnistPredictorInitialize';
function MnistPredict(image:Pbyte):longint;cdecl;external External_library name 'MnistPredict';
procedure MnistPredictorFinalize;cdecl;external External_library name 'MnistPredictorFinalize';

implementation


end.
