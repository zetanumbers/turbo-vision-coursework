struct FuturePrediction;

struct Predictor;

char *BlockingPredict(Predictor *state, const unsigned char *image);

void FinalizePredictor(Predictor *p);

Predictor *InitializePredictor(void);

void RecycleResultMessage(char *s);

FuturePrediction *StartPrediction(Predictor *state, const unsigned char *image);

void ThrowAwayPrediction(FuturePrediction *futr);

char *TryGetPredictionResult(FuturePrediction *futr);
