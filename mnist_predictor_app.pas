{************************************************}

 {   Turbo Pascal 6.0                             }
 {   Demo program from the Turbo Vision Guide     }

{   Copyright (c) 1990 by Borland International  }

{************************************************}

program mnist_predictor_app;

uses
  Objects,
  Drivers,
  Views,
  Menus,
  App,
  mnist_predictor;

const
  MnistImageShapeX = 28;
  MnistImageShapeY = 28;
  MnistImageSize = 784;
  cmFileOpen = 100;
  cmNewWin = 101;

  cmClearCanvas  = 102;
  CanvasCommands = [cmClearCanvas];

  BrushLoX = -2;
  BrushLoY = -2;
  BrushHiX = 1;
  BrushHiY = 1;
  BrushMask: array[BrushLoX..BrushHiX, BrushLoY..BrushHiY] of Byte =
    ((96 , 255, 255, 96 ), 
     (255, 255, 255, 255), 
     (255, 255, 255, 255), 
     (96 , 255, 255, 96 ));
type
  PMyApp = ^TMyApp;
  TMyApp = object(TApplication)
    WinCount: integer;
    MyPredictor: PPredictor;
    constructor Init;
    destructor Done; virtual;
    procedure Idle; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure InitMenuBar; virtual;
    procedure InitStatusLine; virtual;
    procedure NewWindow;
    function GetPalette: PPalette; virtual;
  end;

  PDemoWindow = ^TDemoWindow;

  TDemoWindow = object(TWindow)
    LocalFuture: PFuturePrediction;
    LeftButtonPressed, RightButtonPressed: boolean;
    MouseLocalPos: TPoint;
    Canvas: array[0..MnistImageShapeY - 1, 0..MnistImageShapeX - 1] of byte;
    PredictedLabel: shortstring;
    constructor Init(Bounds: TRect; WinTitle: string; WindowNo: integer);
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure Draw; virtual;
    procedure DrawDebugInfo;
    procedure DrawCanvas;
    procedure ClearCanvas;
    procedure UpdateCanvas;
    function UpdateLabel: Boolean;
    procedure StartComputing;
    procedure RegisterPresses(var Event: TEvent);
    procedure RegisterMove(var Event: TEvent);
    procedure SetState(AState: word; Enable: boolean); virtual;
    function GetPalette: PPalette; virtual;
  end;

  function Clamp(val, min, max: longint): longint;
  begin
    if val < min then
      Clamp := min
    else if val > max then
      Clamp := max
    else
      Clamp := val;
  end;

  function InRange(val, min, max: longint): Boolean;
  begin
    InRange := (min <= val) and (val <= max);
  end;

  function SaturatedAdd(lhs, rhs: byte): byte;
  begin
    SaturatedAdd := Clamp(longint(lhs) + longint(rhs), 0, 255);
  end;

  function SaturatedSub(lhs, rhs: byte): byte;
  begin
    SaturatedSub := Clamp(longint(lhs) - longint(rhs), 0, 255);
  end;

  { TDemoWindow }
  constructor TDemoWindow.Init(Bounds: TRect; WinTitle: string; WindowNo: integer);
  var
    S: string[3];
  begin
    Str(WindowNo, S);
    TWindow.Init(Bounds, WinTitle + ' ' + S, wnNoNumber);

    LocalFuture := Nil;
    LeftButtonPressed := False;
    RightButtonPressed := False;
    PredictedLabel := 'Draw a digit';
    ClearCanvas;
  end;

  procedure TDemoWindow.Draw;
  begin
    TWindow.Draw;

    UpdateLabel;
    WriteStr(5, 0, PredictedLabel, $01);

    DrawCanvas;
    // DrawDebugInfo;
  end;

  function TDemoWindow.GetPalette: PPalette;
  const
    CDemoWindow = #9#8#10#11#12#13#14#15;
    P: string[Length(CDemoWindow)] = CDemoWindow;
  begin
    GetPalette := @P;
  end;  

  procedure TDemoWindow.DrawDebugInfo;
  var
    S: string[5];
  begin
    if LeftButtonPressed then
      S := 'True'
    else
      S := 'False';
    WriteStr(1, 1, S, $01);

    if RightButtonPressed then
      S := 'True'
    else
      S := 'False';
    WriteStr(1, 2, S, $01);

    Str(MouseLocalPos.X, S);
    WriteStr(1, 3, S, $01);
    Str(MouseLocalPos.Y, S);
    WriteStr(1, 4, S, $01);
  end;

  procedure TDemoWindow.UpdateCanvas;
  var
    Pos, OffsetPos: TPoint;
    OffsetX, OffsetY: integer;
  begin
    Pos := MouseLocalPos;
    if (Cardinal(Pos.X) < MnistImageShapeX) and
      (Cardinal(Pos.Y) < MnistImageShapeY) then
      if LeftButtonPressed then
        for OffsetY := BrushLoY to BrushHiY do
          for OffsetX := BrushLoX to BrushHiX do
          begin
            OffsetPos.X := Pos.X + OffsetX;
            OffsetPos.Y := Pos.Y + OffsetY;
            if InRange(OffsetPos.X, 0, MnistImageShapeX - 1) and InRange(OffsetPos.Y, 0, MnistImageShapeY - 1) then 
            Canvas[OffsetPos.Y, OffsetPos.X] :=
              SaturatedAdd(Canvas[OffsetPos.Y, OffsetPos.X],
              BrushMask[OffsetY, OffsetX]);
          end
      else if RightButtonPressed then
        for OffsetY := BrushLoY to BrushHiY do
          for OffsetX := BrushLoX to BrushHiX do
          begin
            OffsetPos.X := Pos.X + OffsetX;
            OffsetPos.Y := Pos.Y + OffsetY;
            if InRange(OffsetPos.X, 0, MnistImageShapeX - 1) and InRange(OffsetPos.Y, 0, MnistImageShapeY - 1) then 
            Canvas[OffsetPos.Y, OffsetPos.X] :=
              SaturatedSub(Canvas[OffsetPos.Y, OffsetPos.X],
              BrushMask[OffsetY, OffsetX]);
          end
  end;

  function TDemoWindow.UpdateLabel: Boolean;
  var
    temp: PChar;
  begin
    UpdateLabel := False;
    if LocalFuture <> Nil then begin
      temp := TryGetPredictionResult(LocalFuture);
      if temp <> Nil then begin
        PredictedLabel := StrPas(temp);
        RecycleResultMessage(temp);
        LocalFuture := Nil;
        UpdateLabel := True;
      end;
    end;
  end;

  procedure TDemoWindow.StartComputing;
  begin
    if LocalFuture <> Nil then ThrowAwayPrediction(LocalFuture);
    LocalFuture := StartPrediction(PMyApp(Application)^.MyPredictor, @Canvas[0, 0]);
    PredictedLabel := '...';
  end;

  procedure TDemoWindow.ClearCanvas;
  var
    X, Y: integer;
  begin
    for Y := 0 to MnistImageShapeY - 1 do
      for X := 0 to MnistImageShapeX - 1 do
        Canvas[Y, X] := 0;
  end;

  procedure TDemoWindow.DrawCanvas;
  const
    levels: array[0..4] of byte = (0, 113, 176, 227, 255);
    BlockChars: array[0..4] of char = (' ', char($b0), char($b1), char($b2), char($db));
  var
    X, Y, I: integer;
  begin
    for Y := 0 to MnistImageShapeY - 1 do
      for X := 0 to MnistImageShapeX - 1 do
        for I := 0 to 4 do
          if Canvas[Y, X] <= levels[I] then
          begin
            WriteChar(2 * X + 1, Y + 1, BlockChars[I], $01, 2);
            Break;
          end;
  end;

  procedure TDemoWindow.RegisterPresses(var Event: TEvent);
  begin
    LeftButtonPressed  := Event.Buttons and mbLeftButton <> 0;
    RightButtonPressed := Event.Buttons and mbRightButton <> 0;
    ClearEvent(Event);
  end;

  procedure TDemoWindow.RegisterMove(var Event: TEvent);
  begin
    MakeLocal(Event.Where, MouseLocalPos);
    MouseLocalPos.X := MouseLocalPos.X div 2 - 1;
    MouseLocalPos.Y := MouseLocalPos.Y - 1;
  end;

  procedure TDemoWindow.HandleEvent(var Event: TEvent);
  begin
    TWindow.HandleEvent(Event);
    case Event.What of
      evMouseDown: begin
        RegisterPresses(Event);
        UpdateCanvas;
        DrawView;
        ClearEvent(Event);
      end;
      evMouseUp: begin
        RegisterPresses(Event);
        StartComputing;
        DrawView;
        ClearEvent(Event);
      end;
      evMouseMove: begin
        RegisterMove(Event);
        if LeftButtonPressed or RightButtonPressed then begin
          UpdateCanvas;
          DrawView;
        end;
        ClearEvent(Event);
      end;
      evCommand:
        case Event.Command of
          cmClearCanvas:
          begin
            ClearCanvas;
            DrawView;
            ClearEvent(Event);
          end;
        end;
    end;
  end;

  procedure TDemoWindow.SetState(AState: word; Enable: boolean);
  begin
    TWindow.SetState(AState, Enable);
    if AState = sfSelected then
      if Enable then
        EnableCommands(CanvasCommands)
      else
        DisableCommands(CanvasCommands);
  end;

  { TMyApp }
  constructor TMyApp.Init;
  begin
    TApplication.Init;
    WinCount := 0;
    MyPredictor := InitializePredictor;
  end;

  destructor TMyApp.Done;
  begin
    FinalizePredictor(MyPredictor);
    TApplication.Done;
  end;
  
  procedure TMyApp.Idle; 
    procedure UpdateLabelForCanvas(P: PView);
    var
      PCW: PDemoWindow;
    begin
      if TypeOf(P^) = TypeOf(TDemoWindow) then begin
        PCW := PDemoWindow(P);
        if PCW^.UpdateLabel then
          PCW^.DrawView;
      end;
    end;
  begin
    DeskTop^.ForEach(@UpdateLabelForCanvas);
  end;

  procedure TMyApp.HandleEvent(var Event: TEvent);
  begin
    TApplication.HandleEvent(Event);

    if Event.What = evCommand then
    begin
      case Event.Command of
        cmNewWin: NewWindow;
        else
          Exit;
      end;
      ClearEvent(Event);
    end;
  end;

  procedure TMyApp.InitMenuBar;
  var
    R: TRect;
  begin
    GetExtent(R);
    R.B.Y := R.A.Y + 1;
    MenuBar := New(PMenuBar, Init(R, NewMenu(
      NewSubMenu('~F~ile', hcNoContext, NewMenu(
      NewItem('~O~pen', 'F3', kbF3, cmFileOpen, hcNoContext,
      NewItem('~N~ew', 'F4', kbF4, cmNewWin, hcNoContext, NewLine(
      NewItem('E~x~it', 'Alt-X', kbAltX, cmQuit, hcNoContext, nil))))),
      NewSubMenu('~W~indow', hcNoContext, NewMenu(
      NewItem('~N~ext', 'F6', kbF6, cmNext, hcNoContext,
      NewItem('~Z~oom', 'F5', kbF5, cmZoom, hcNoContext, nil))), nil)))));
  end;

  procedure TMyApp.InitStatusLine;
  var
    R: TRect;
  begin
    GetExtent(R);
    R.A.Y := R.B.Y - 1;
    StatusLine := New(PStatusLine,
      Init(R, NewStatusDef(0, $FFFF, NewStatusKey('', kbF10, cmMenu,
      NewStatusKey('~Alt-X~ Exit', kbAltX, cmQuit,
      NewStatusKey('~F4~ New', kbF4, cmNewWin,
      NewStatusKey('~Alt-F3~ Close', kbAltF3, cmClose,
      NewStatusKey('~Del~ Clear Canvas', kbDel, cmClearCanvas, nil))))), nil)));
    DisableCommands(CanvasCommands);
  end;

  procedure TMyApp.NewWindow;
  var
    Window: PDemoWindow;
    R: TRect;
  begin
    Inc(WinCount);
    R.Assign(0, 0, MnistImageShapeX * 2 + 2, MnistImageShapeY + 2);
    R.Move(WinCount, WinCount);
    Window := New(PDemoWindow, Init(R, 'Demo Window', WinCount));
    DeskTop^.Insert(Window);
  end;

  function TMyApp.GetPalette: PPalette;
  const
    P: string[Length(CMonochrome)] = CBlackWhite;
  begin
    GetPalette := @P;
  end;  



var
  MyApp: TMyApp;

begin
  MyApp.Init;
  MyApp.Run;
  MyApp.Done;
end.
