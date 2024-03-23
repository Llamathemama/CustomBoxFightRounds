
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Fortnite.com/Playspaces }
using {/Fortnite.com/Characters }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/Teams }
using { /Fortnite.com/FortPlayerUtilities }
using{ /Verse.org/Colors}

# See https://dev.epicgames.com/documentation/en-us/uefn/create-your-own-device-in-verse for how to create a verse device.

# A Verse-authored creative device that can be placed in a level
Custom_Round := class(creative_device):
    @editable
    var PlayerCounterDevices : []player_counter_device = array{}
    var locations : []vector3 = array{}
    var RoundNum : int = 1
    var Enumerate : int = 0
    @editable
    var LocationProps : []creative_prop = array{}
    var TeamOneWins : int = 0
    var TeamTwoWins : int = 0
    Message<localizes>(Str : string) : message = "{Str}"
    # Runs when the device is started in a running game
    OnBegin<override>()<suspends>:void=
       TeamSelect()
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
        for(TeamNum := 1..2){
        if(Team := TeamInterface.GetAgents[Teams[TeamNum]]){
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
        Sleep(1.0)
        TeamThatWon := CheckIfRoundIsOver()
        Print("Team {ToString(TeamThatWon)} has won the match")
        if(TeamThatWon = 1){
            set TeamOneWins += 1
        }
        else if(TeamThatWon = 2){
            set TeamTwoWins += 1
        }
        set RoundNum += 1
        Print("Round Number {RoundNum} concluding")
        RoundStart()
       
       
    TeamSelect()<suspends>:void=
        loop:
            if(cat := PlayerCounterDevices[0].GetCount()){
                Print(ToString(cat))
            }
            # Remember to change this later
            if(PlayerCounterDevices[0].GetCount() = 1 or PlayerCounterDevices[1].GetCount()=2){
                TeamInterface := GetPlayspace().GetTeamCollection()
                Teams := TeamInterface.GetTeams()
                Players := GetPlayspace().GetPlayers()
                for(Player : Players){
                    if(PlayerCounterDevices[0].IsCounted[Player]){
                        if(TeamInterface.AddToTeam[Player,Teams[1]]){}
                    }
                    if(PlayerCounterDevices[1].IsCounted[Player]){
                        if(TeamInterface.AddToTeam[Player,Teams[1]]){}
                    }
                break
                    
                }
            }
            Sleep(1.0)
    CheckIfRoundIsOver()<suspends>:int=
        TeamInterface := GetPlayspace().GetTeamCollection()
        Teams := TeamInterface.GetTeams()
        Players := GetPlayspace().GetPlayers()
        var IsTeamSpectating : int = 0
        loop:
            var TestMode : logic = true
            if(TestMode?){
                Sleep(8.0)
                return 2
            }
            for(X := 1..2){
                Print("Beginning enumeration {X})")
                set IsTeamSpectating = 0
                for(Player : Players){
                    if(TeamArray := TeamInterface.GetAgents[Teams[X]]){
                        for(Plyr : TeamArray){
                            if(Plyr = Player){
                                set IsTeamSpectating += 1
                                Print("Spectating match found")
                            }
                        }
                    }
                }
                if(IsTeamSpectating = 2){
                    return IsTeamSpectating
                }
            }
            Sleep(1.0)
            
            
        
                
          
 




        