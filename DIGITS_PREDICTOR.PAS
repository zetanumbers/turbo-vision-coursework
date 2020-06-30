{************************************************}

 {   Turbo Pascal 6.0                             }
 {   Demo program from the Turbo Vision Guide     }

{   Copyright (c) 1990 by Borland International  }

{************************************************}

program DIGITS_PREDICTOR;

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
type
  TMyApp = object(TApplication)
    WinCount: integer;
    constructor Init;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure InitMenuBar; virtual;
    procedure InitStatusLine; virtual;
    procedure NewWindow;
  end;

  PDemoWindow = ^TDemoWindow;

  TDemoWindow = object(TWindow)
    LeftButtonPressed, RightButtonPressed: boolean;
    MouseLocalPos: TPoint;
    Canvas: array[0..MnistImageShapeY - 1, 0..MnistImageShapeX - 1] of byte;
    PredictedLabel: Integer;
    constructor Init(Bounds: TRect; WinTitle: string; WindowNo: integer);
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure Draw; virtual;
    procedure DrawDebugInfo;
    procedure DrawCanvas;
    procedure ClearCanvas;
    procedure UpdateCanvas;
    procedure UpdateLabel;
    procedure RegisterPresses(var Event: TEvent);
    procedure RegisterMove(var Event: TEvent);
    procedure SetState(AState: word; Enable: boolean); virtual;
  end;

  function Clamp(val, min, max: longint): longint;
  begin
    if val < min then
      Result := min
    else if val > max then
      Result := max
    else
      Result := val;
  end;

  function SaturatedAdd(lhs, rhs: byte): byte;
  begin
    Result := Clamp(longint(lhs) + longint(rhs), 0, 255);
  end;

  function SaturatedSub(lhs, rhs: byte): byte;
  begin
    Result := Clamp(longint(lhs) - longint(rhs), 0, 255);
  end;

  { TDemoWindow }
  constructor TDemoWindow.Init(Bounds: TRect; WinTitle: string; WindowNo: integer);
  var
    S: string[3];
  begin
    Str(WindowNo, S);
    TWindow.Init(Bounds, WinTitle + ' ' + S, wnNoNumber);

    LeftButtonPressed := False;
    RightButtonPressed := False;
    PredictedLabel := 0;
    ClearCanvas;
  end;

  procedure TDemoWindow.Draw;
  var
    S: string[3];
  begin
    TWindow.Draw;

    Str(PredictedLabel, S);
    WriteStr(5, 0, S, $01);

    DrawCanvas;
    // DrawDebugInfo;
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
  const
    BrushMask: array[-1..1, -1..1] of byte =
      ((16, 63, 16),
      (63, 255, 63),
      (16, 63, 16));
  var
    Pos, OffsetPos: TPoint;
    OffsetX, OffsetY: integer;
  begin
    Pos := MouseLocalPos;
    if (Pos.X in [0 .. MnistImageShapeX - 1]) and
      (Pos.Y in [0 .. MnistImageShapeY - 1]) then
      if LeftButtonPressed then
        for OffsetY := -1 to 1 do
          for OffsetX := -1 to 1 do
          begin
            OffsetPos.X := Clamp(Pos.X + OffsetX, 0, MnistImageShapeX - 1);
            OffsetPos.Y := Clamp(Pos.Y + OffsetY, 0, MnistImageShapeY - 1);
            Canvas[OffsetPos.Y, OffsetPos.X] :=
              SaturatedAdd(Canvas[OffsetPos.Y, OffsetPos.X],
              BrushMask[OffsetY, OffsetX]);
          end
      else if RightButtonPressed then
        for OffsetY := -1 to 1 do
          for OffsetX := -1 to 1 do
          begin
            OffsetPos.X := Clamp(Pos.X + OffsetX, 0, MnistImageShapeX - 1);
            OffsetPos.Y := Clamp(Pos.Y + OffsetY, 0, MnistImageShapeY - 1);
            Canvas[OffsetPos.Y, OffsetPos.X] :=
              SaturatedSub(Canvas[OffsetPos.Y, OffsetPos.X],
              BrushMask[OffsetY, OffsetX]);
          end;
  end;

  procedure TDemoWindow.UpdateLabel;
  begin
    PredictedLabel := MnistPredict(@Canvas[0, 0]);
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
    levels: array[0..4] of byte = (0, 115, 156, 193, 255);
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
        UpdateLabel;
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

var
  MyApp: TMyApp;

begin
  MnistPredictorInitialize;
  MyApp.Init;
  MyApp.Run;
  MyApp.Done;
  MnistPredictorFinalize;
end.
