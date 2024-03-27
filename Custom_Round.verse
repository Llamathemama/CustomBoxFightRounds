
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Fortnite.com/Playspaces }
using {/Fortnite.com/Characters }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/Teams }
using { /Fortnite.com/FortPlayerUtilities }
using{ /Verse.org/Colors}
using{ /UnrealEngine.com/Temporary/UI }
using{ /Verse.org/Assets }
using { /Fortnite.com/UI }

# See https://dev.epicgames.com/documentation/en-us/uefn/create-your-own-device-in-verse for how to create a verse device.

# A Verse-authored creative device that can be placed in a level
Custom_Round := class(creative_device):
    @editable
    var PlayerCounterDevices : []player_counter_device = array{}
    @editable
    var Barrier_Devices : []barrier_device = array{}
    @editable 
    var EndGame : end_game_device = end_game_device{}
    @editable
    var ItemGranterDevices : []item_granter_device = array{}
    @editable
    var RematchCounter : player_counter_device = player_counter_device{}
    @editable
    var TestModeOn : logic = false
    @editable
    var Timer_Device : timer_device = timer_device{}
    var locations : []vector3 = array{}
    var RoundNum : int = 1
    var Enumerate : int = 0
    @editable
    var LocationProps : []creative_prop = array{}
    var TeamOneWins : int = 0
    var TeamTwoWins : int = 0
    @editable 
    var NumberOfScenarios : int = 0
    var ButtonArray : []text_button_base = array{}
    var VotingArray : []int = array{0,0,0,0,0}
    var LastVote : [player]int = map{}
    var GranterToUse : int = 0
    var UIMap : [player]?canvas = map{}
    
    
    S2M<localizes>(S : string) : message = "{S}"
    HudEvent<public>:event() = event(){}
    RoundEndEvent<public>:event() = event(){}
    Message<localizes>(Str : string) : message = "{Str}"
    # Runs when the device is started in a running game
    OnBegin<override>()<suspends>:void=
       TeamSelect()
       InitVoting()
        PopulateLocationArray()
        RoundStart()

    PopulateLocationArray():void=
        for(Prop : LocationProps){
            Location := Prop.GetTransform()
            Prop.Hide()
            Prop.Dispose()
            set locations += array{Location.Translation}
        }
    

    RoundStart()<suspends>:void=
        Players := GetPlayspace().GetPlayers()
        TeamInterface := GetPlayspace().GetTeamCollection()
        Teams := TeamInterface.GetTeams()
        for(Barrier : Barrier_Devices){
            Barrier.Enable()
        }
        for(TeamNum := 1..2){
            Print("Performing Action for Team {TeamNum}.",?Duration := 5.0)
        if(Team := TeamInterface.GetAgents[Teams[TeamNum]]){
            # Check if a team has had all members leave
            if(Team.Length = 0){
                if(TeamNum = 1,TeamWinsByDefault := Teams[2]){
                    HandleGameEnd(TeamWinsByDefault, "Team 1 Wins")
                }
                else if(TeamWinsByDefault := Teams[1]){
                    HandleGameEnd(TeamWinsByDefault, "Team 2 Wins")
                }
            }
            for(Player : Team){
                if(Ply := Player.GetFortCharacter[]){
                    Rotation := Ply.GetViewRotation()
                    if(Ply.TeleportTo[locations[Enumerate], Rotation]){
                        if(Team.Length <> 2){
                            set Enumerate += 2 - Team.Length
                        }
                        Print("Teleport success for team {TeamNum}")
                        Print("Should spawn at Cube {Enumerate}", ?Color := NamedColors.Gold)
                    }
                }
                set Enumerate += 1
                }
            }
        }
        for(Player : Players){
            if(ItemGranter := ItemGranterDevices[GranterToUse]){
            ItemGranter.GrantItem(Player)
            }
        }

        Timer_Device.Start()
        Timer_Device.SuccessEvent.Subscribe(RoundCountdown)
        HudEvent.Await()
        for(Barrier : Barrier_Devices){
            Barrier.Disable()
        }
        Sleep(5.0)
        TeamThatWon := CheckIfRoundIsOver()
        Print("Team {ToString(TeamThatWon)} has won the match")
        if(TeamThatWon = 1){
            set TeamOneWins += 1
        }
        else if(TeamThatWon = 2){
            set TeamTwoWins += 1
        }
        Print("Enumeration: {Enumerate}")
        set RoundNum += 1
        Print("Round Number {RoundNum} concluding")
        for(Player : Players){
            Player.Respawn(vector3{X := 0.0,Y := 0.0,Z := 0.0}, rotation{})
        }
        if(Enumerate >= NumberOfScenarios*4){
            set Enumerate = 0
        }
        if(TeamOneWins = 10,Team := Teams[1]){
            HandleGameEnd(Team, "Team 1 Wins")
        }
        
        if(TeamTwoWins = 10,Team := Teams[2]){
            HandleGameEnd(Team, "Team 2 Wins")
        }
        RoundStart()
       
       
    TeamSelect()<suspends>:void=
        loop:
            if(cat := PlayerCounterDevices[0].GetCount()){
                Print(ToString(cat))
            }
            # Remember to change this later
            if(PlayerCounterDevices[0].GetCount() = 2 or PlayerCounterDevices[1].GetCount()=2){
                TeamInterface := GetPlayspace().GetTeamCollection()
                Teams := TeamInterface.GetTeams()
                Players := GetPlayspace().GetPlayers()
                for(Player : Players){
                    if(PlayerCounterDevices[0].IsCounted[Player]){
                        if(TeamInterface.AddToTeam[Player,Teams[1]]){}
                    }
                    if(PlayerCounterDevices[1].IsCounted[Player]){
                        if(TeamInterface.AddToTeam[Player,Teams[2]]){}
                    }
                break
                    
                }
            }
            Sleep(1.0)
    InitVoting()<suspends>:void=
        Players := GetPlayspace().GetPlayers()
        for(Player : Players){
            if(PlayerUI := GetPlayerUI[Player], set LastVote[Player] = -1){
                UI := MakeCanvas()
                if(set UIMap[Player] = option{UI}){}
                PlayerUI.AddWidget(UI,player_ui_slot{InputMode := ui_input_mode.All})
            }
        }
        Sleep(15.0)
        set GranterToUse = GetMaxValue(VotingArray)
        for(Player : Players){
            if(PlayerUI := GetPlayerUI[Player], MyUI := UIMap[Player]?){
                PlayerUI.RemoveWidget(MyUI)
                if(set UIMap[Player] = false){}
            }
        }
        
    HandleGameEnd(Team : team, WinMessage : string)<suspends>:void=
        Players := GetPlayspace().GetPlayers()
        TeamInterface := GetPlayspace().GetTeamCollection()
        Teams := TeamInterface.GetTeams()
        # Replace the vector 3 with cords of the room
        for(Player : Players){
            Player.Respawn(vector3{X:=1536.0, Y := 6400.0, Z:= 0.0},rotation{})
        }
        RematchCounter.CountSucceedsEvent.Subscribe(RematchSignal)
        RoundEndEvent.Await()
        if(EndTeam := TeamInterface.GetAgents[Team], EndAgent := EndTeam[0]){
            EndGame.Activate(EndAgent)
        }

        
    CheckIfRoundIsOver()<suspends>:int=
        TeamInterface := GetPlayspace().GetTeamCollection()
        Teams := TeamInterface.GetTeams()
        Players := GetPlayspace().GetPlayers()
        var IsTeamSpectating : int = 0

        loop:
            var TestMode : logic = TestModeOn
            if(TestMode?){
                Sleep(8.0)
                return 2
            }
            for(X := 1..2){
                Print("Beginning enumeration {X})")
                for(Player : Players){
                    set IsTeamSpectating = 0
                    if(TeamArray := TeamInterface.GetAgents[Teams[X]]){
                        for(Plyr : TeamArray){
                            if(Plyr = Player and Player.IsSpectator[]){
                                set IsTeamSpectating += 1
                                Print("Spectating match found")
                                if(IsTeamSpectating = 2){
                                    if(X = 1){
                                        return 1
                                    }
                                    else{
                                        return 2
                                    }
                                    
                                }
                
                            }
                        }
                    }
                }
            }
            Sleep(1.0)
    RematchSignal():void=
        RoundEndEvent.Signal()
    RoundCountdown(Agent : ?agent):void=
        HudEvent.Signal()
    MakeCanvas():canvas=
        SizeStackBox := vector2{X:=1666.900269,Y:=669.295959}
        ImageSize := vector2{X:=307.758881,Y:=1342.407104}
        MyStackBox:=stack_box:  
            Orientation := orientation.Horizontal
            Slots := array:
                stack_box_slot:
                    Widget := texture_block{DefaultImage:= VotingUIWidgets.loadout1,DefaultDesiredSize := ImageSize}
                    Padding := margin{Top := 10.0, Bottom := 10.0,Left := 10.0, Right := 10.0}
                stack_box_slot:
                    Widget := texture_block{DefaultImage:= VotingUIWidgets.loadout2,DefaultDesiredSize := ImageSize}
                    Padding := margin{Top := 10.0, Bottom := 10.0,Left := 10.0, Right := 10.0}
                stack_box_slot:
                    Widget := texture_block{DefaultImage:= VotingUIWidgets.loadout3,DefaultDesiredSize := ImageSize}
                    Padding := margin{Top := 10.0, Bottom := 10.0,Left := 10.0, Right := 10.0}
                stack_box_slot:
                    Widget := texture_block{DefaultImage:= VotingUIWidgets.loadout4,DefaultDesiredSize := ImageSize}
                    Padding := margin{Top := 10.0, Bottom := 10.0,Left := 10.0, Right := 10.0}
                stack_box_slot:
                    Widget := texture_block{DefaultImage:= VotingUIWidgets.loadout5,DefaultDesiredSize := ImageSize}
                    Padding := margin{Top := 10.0, Bottom := 10.0,Left := 10.0, Right := 10.0}
                    
             
        #MakeCanvasSlot(Widget:=MyStackBox,Position:=vector2{X:= 135.855835,Y:=173.933899},?Size:= SizeStackBox)   
        MyUI : canvas = canvas:
            Slots := array:
                canvas_slot:
                    Widget := button_quiet{DefaultText := S2M("Vote - {}") }
                    
        ButtonsToBeCreated := array{192.0,520.0,848.0,1172.0,1504.0}
        for(Index -> Cord : ButtonsToBeCreated){
            ButtonToAdd := ButtonClass{XCord:=Cord}
            NewButton := ButtonToAdd.CreateButton()
            ButtonWidget := ButtonToAdd.CanvasSlotForButton(NewButton)
            set ButtonArray += array{NewButton}
            MyUI.AddWidget(ButtonWidget)
            NewButton.OnClick().Subscribe(HandleVoting)
        }
        
        MyUI.AddWidget(MakeCanvasSlot(Widget:=MyStackBox,Position:=vector2{X:= 135.855835,Y:=173.933899},?Size:= SizeStackBox))
        return MyUI
    HandleVoting(Newmessage : widget_message):void=
        Print("This function was called",?Color := NamedColors.Gold)
        for(Index -> Select : ButtonArray){
            if(Newmessage.Source = Select,DebugVar := LastVote[Newmessage.Player]){
                Print("Did It find a match")
                Print("Last Vote {DebugVar}", ?Color := NamedColors.Red)
                if(set VotingArray[Index] += 1,Send := VotingArray[Index]){
                    Select.SetText(S2M("Votes - {Send}"))
                    if(LastVote[Newmessage.Player] <> -1 or LastVote[Newmessage.Player] <> Index,  Index,VoteToReduce := LastVote[Newmessage.Player]){
                        if(set VotingArray[VoteToReduce] -= 1, ReduceSend := VotingArray[VoteToReduce], ButtonToReduce := ButtonArray[LastVote[Newmessage.Player]]){
                            ButtonToReduce.SetText(S2M("Votes - {ReduceSend}"))
                            if(set LastVote[Newmessage.Player] = Index){}
                        }
                        else if(set LastVote[Newmessage.Player] = Index){}
                    }
                    
                        
                    
                }
            }
        }
    GetMaxValue(MyArray : []int):int=
        var CurValue : int = 0
        for(Value : MyArray){
            if(Value > CurValue){
                set CurValue = Value
            }
        }
        return CurValue

ButtonClass := class:
    XCord:float
    S2M<localizes>(S : string): message = "{S}"
    CreateButton():button_quiet=
        ButtonInit := button_quiet{DefaultText := S2M("Votes - 0")}
        return ButtonInit
    CanvasSlotForButton(B : text_button_base):canvas_slot=
        Slot := MakeCanvasSlot(Widget:=B,Position:=vector2{X:=XCord,Y:=748.0}, ?Size := vector2{X := 218.118118, Y:=56.016014})
        return Slot

    
   
        
        

                
            
            
        
                
          
 




        