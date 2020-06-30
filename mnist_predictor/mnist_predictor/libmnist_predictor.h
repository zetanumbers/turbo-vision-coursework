#ifndef MNISTPREDICTOR_H
#define MNISTPREDICTOR_H

#ifdef __cplusplus
extern "C" {
#endif

void MnistPredictorInitialize();
__int32 MnistPredict(const unsigned char* image);
void MnistPredictorFinalize();

#ifdef __cplusplus
}
#endif

#endif
