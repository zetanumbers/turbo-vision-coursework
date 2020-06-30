#ifndef MNISTPREDICTOR_H
#define MNISTPREDICTOR_H

#ifdef MNISTPREDICTOR_EXPORTS
#define MNISTPREDICTOR_API __declspec(dllexport)
#else
#define MNISTPREDICTOR_API __declspec(dllimport)
#endif

#ifdef __cplusplus
extern "C" {
#endif

MNISTPREDICTOR_API void MnistPredictorInitialize();
MNISTPREDICTOR_API __int32 MnistPredict(const unsigned char* image);
MNISTPREDICTOR_API void MnistPredictorFinalize();

#ifdef __cplusplus
}
#endif

#endif
