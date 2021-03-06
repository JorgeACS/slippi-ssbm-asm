#To be inserted at 801a45bc
.include "../../Common/Common.s"
.include "Online/Online.s"
#.include "../Globals.s"
.include "Header.s"

.set  ExitSceneID,40

#region Init New Scenes
.set  REG_MinorSceneStruct,31

#Init and backup
  backup

################################################################################
# Set text entry keyboard to qwerty
################################################################################
/*
  load r3, 0x803EDC1C # destination
  bl DATA_BLRL
  mflr r4
  addi r4, r4, DOFST_QWERTY_LAYOUT
  li r5, QWERTY_LAYOUT_LEN
  branchl r12, memcpy
*/

################################################################################
# Initialize hashtag letter in text entry
################################################################################
  load r4, 0x803EDC1C # Start of keyboard (top-right, goes down first)
  bl DATA_BLRL
  mflr r3
  addi r3, r3, DOFST_HASHTAG_LETTER
  stw r3, 0x8(r4) # Third letter down from top-right

################################################################################
# Initialize some variables
################################################################################
  li r3, 0
  stb r3, OFST_R13_NAME_ENTRY_MODE(r13)
  stb r3, OFST_R13_ISPAUSE(r13)

################################################################################
# Set up Slippi major scene
################################################################################
#Init Slippi major struct
  li  r3,SlippiMajorID
  bl  Slippi_MinorSceneStruct
  mflr  r4
  bl  InitializeMajorSceneStruct

  b Injection_Exit

#region PointerConvert
PointerConvert:
  lwz r4,0x0(r3)          #Load bl instruction
  rlwinm r5,r4,8,25,29    #extract opcode bits
  cmpwi r5,0x48           #if not a bl instruction, exit
  bne PointerConvert_Exit
  rlwinm  r4,r4,0,6,29  #extract offset bits
  extsh r4,r4
  add r4,r4,r3
  stw r4,0x0(r3)
PointerConvert_Exit:
  blr
#endregion
#region InitializeMajorSceneStruct
InitializeMajorSceneStruct:
.set  REG_MajorScene,31
.set  REG_MinorStruct,30

#Init
  backup
  mr  REG_MajorScene,r3
  mr  REG_MinorStruct,r4

# Set up Load and Unload functions
/*
Major Scene Table:
    -Starts at 803daca4
    -Stride is 0x14
    -Structure is:
        -0x0 = Preload Bool. (0x0 = No Preload, 0x1 = Preload)
        -0x1 = Major Scene ID
        -0x2 = Unk
        -0x3 = Unk
        -0x4 = Pointer to MajorLoad Function (is run upon entering the major)
        -0x8 = Pointer to MajorUnload Function (is run upon leaving the major)
        -0xC = Pointer to MajorOnBoot Function (is run on boot to init global stuff)
        -0x10 = Pointer to Minor Scenes Tables
*/
  load r4, 0x803dad30 # Start of 0x8 major scene table entry
  bl MajorSceneLoad
  mflr r3
  stw r3, 0x4(r4)
  bl MajorSceneUnload
  mflr r3
  stw r3, 0x8(r4)
  li  r3,1
  stb r3,0x0(r4)    # preload bool


#Get major scene struct
  branchl r12,0x801a50ac
GetMajorStruct_Loop:
  lbz	r4, 0x0001 (r3)
  cmpw r4,REG_MajorScene
  beq GetMajorStruct_Exit
  addi  r3,r3,20
  b GetMajorStruct_Loop
GetMajorStruct_Exit:

InitMinorSceneStruct:
.set  REG_MinorStructParse,20
  stw REG_MinorStruct,0x10(r3)
  mr  REG_MinorStructParse,REG_MinorStruct
InitMinorSceneStruct_Loop:
#Check if valid entry
  lbz r3,0x0(REG_MinorStructParse)
  extsb r3,r3
  cmpwi r3,-1
  beq InitMinorSceneStruct_Exit
#Convert Pointers
  addi  r3,REG_MinorStructParse,0x4
  bl  PointerConvert
  addi  r3,REG_MinorStructParse,0x8
  bl  PointerConvert
  addi  REG_MinorStructParse,REG_MinorStructParse,0x18
  b InitMinorSceneStruct_Loop
InitMinorSceneStruct_Exit:

  restore
  blr
#endregion
#endregion

#endregion

MajorSceneLoad:
blrl
backup

# Set the proper 1p port for CSS
load r4, 0x8045abf0
lbz r3, -0x5108(r13) # player index
stb r3, 0x6(r4)

################################################################################
# Set up Zelda to select Sheik as default
################################################################################
li r3, 0x13
load r4, 0x803f0cc8
stb r3, 0x1(r4)

restore
blr

MajorSceneUnload:
blrl
backup

################################################################################
# Set up Zelda to select Zelda as default
################################################################################
li r3, 0x12
load r4, 0x803f0cc8
stb r3, 0x1(r4)

restore
blr

SplashSceneDecide:
backup

# This will cause the next scene to be VS mode
load r4, 0x80479d30
li r3, 0x03
stb r3, 0x5(r4)

restore
blr

#region MinorSceneStruct
Slippi_MinorSceneStruct:
blrl
#CSS
.byte 0                     #Minor Scene ID
.byte 3                    #Amount of persistent heaps
.align 2
bl CSSScenePrep             #ScenePrep (event css prep), prev 0x801baa60
bl CSSSceneDecide        #SceneDecide, previously 0x801baad0
.byte 8                     #Common Minor ID (CSS)
.align 2
.long 0x80497758           #Minor Data 1
.long 0x80497758           #Minor Data 2
#SSS
.byte 1                     #Minor Scene ID
.byte 3                    #Amount of persistent heaps
.align 2
.long 0x801b1514            #ScenePrep
.long 0x801b154c            #SceneDecide
.byte 9                     #Common Minor ID (SSS)
.align 2
.long 0x80480668            #Minor Data 1
.long 0x80480668            #Minor Data 2
#VS
.byte 2                     #Minor Scene ID
.byte 3                    #Amount of persistent heaps
.align 2
.long 0x801b1588            #ScenePrep
.long 0x801b15c8  #SceneDecide
.byte 2                    #Common Minor ID (VS Mode)
.align 2
.long 0x80480530            #Minor Data 1
.long 0x80479d98            #Minor Data 2
#Results
.byte 3                     #Minor Scene ID
.byte 3                    #Amount of persistent heaps
.align 2
.long 0x00000000            #ScenePrep
.long 0x00000000            #SceneDecide
.byte 5                    #Common Minor ID (Results)
.align 2
.long 0x00000000            #Minor Data 1
.long 0x00000000            #Minor Data 2
#Splash
.byte 4                     #Minor Scene ID
.byte 3                    #Amount of persistent heaps
.align 2
bl SplashScenePrep          #ScenePrep, previously 0x801b3500
bl SplashSceneDecide
.byte 0x20                  #Common Minor ID (Classic Mode Splash)
.align 2
.long 0x80490880            #Minor Data 1
.long 0x804d68d0            #Minor Data 2
#End
.byte -1
.align 2

DATA_BLRL:
blrl
# Hashtag Letter
.set DOFST_HASHTAG_LETTER, 0
.long 0x81940000
/*
.set DOFST_QWERTY_LAYOUT, DOFST_HASHTAG_LETTER + 4
.set QWERTY_LAYOUT_LEN, 50 * 4
.long 0x804D4DD4
.long 0x804D4CAC
.long 0x804D4CAC
.long 0x804D4D98
.long 0x804D4D9C
.long 0x804D4DE8
.long 0x804D4E24
.long 0x804D4CAC
.long 0x804D4DA8
.long 0x804D4DAC
.long 0x804D4DA0
.long 0x804D4E38
.long 0x804D4CAC
.long 0x804D4DB8
.long 0x804D4DBC
.long 0x804D4E3C
.long 0x804D4D90
.long 0x804D4E10
.long 0x804D4DC8
.long 0x804D4DCC
.long 0x804D4DEC
.long 0x804D4DB0
.long 0x804D4DFC
.long 0x804D4DDC
.long 0x804D4DE0
.long 0x804D4D94
.long 0x804D4DC0
.long 0x804D4E20
.long 0x804D4DF0
.long 0x804D4DF4
.long 0x804D4DB4
.long 0x804D4DD0
.long 0x804D4E28
.long 0x804D4E04
.long 0x804D4E08
.long 0x804D4DE4
.long 0x804D4DF8
.long 0x804D4E0C
.long 0x804D4E18
.long 0x804D4E1C
.long 0x804D4E14
.long 0x804D4DA4
.long 0x804D4E00
.long 0x804D4E2C
.long 0x804D4E30
.long 0x804D4DC4
.long 0x804D4E34
.long 0x804D4DD8
.long 0x804D4E40
.long 0x804D4E44
*/
#endregion

#region CSSScenePrep
CSSScenePrep:
backup

#Restore saved fighter choice
lwz	r4, -0x77C0 (r13)
addi	r31, r4, 1328
branchl r12,0x801A427C
lbz	r5, 0x0002 (r31)
li	r4, 14
lbz	r7, 0x0003 (r31)
li	r6, 0
lbz	r8, 0x0004 (r31)
lbz	r10, 0x0006 (r31)
li	r9, 0
branchl r12,0x801B06B0

#Clear preload cache
branchl r12,0x800174bc

restore
blr
#endregion
#region CSSSceneDecide
CSSSceneDecide:
.set REG_MSRB_ADDR, 31
.set REG_MINORSCENE, 30
.set REG_EVENTCSS_DATA,29
.set REG_VS_SSS_DATA, 28

backup
mr  REG_MINORSCENE,r3

# Run event mode CSS SceneDecide to save HMN character choice
branchl r12,0x801baad0

# Run generic CSS Scene Decide Copy ? to static match data
#branchl r12,0x801b14dc

# Check how CSS was exited
lwz r4,0x14(REG_MINORSCENE)
lbz r4,0x3(r4)
cmpwi r4,2
bne CSSSceneDecide_Advance
# Go back to Main Menu
#li  r3,1
#branchl r12,0x801a42f8
b CSSSceneDecide_Exit

CSSSceneDecide_Advance:
# Get match state info
li r3, 0
branchl r12, FN_LoadMatchState
mr REG_MSRB_ADDR, r3

# Copy Match Info. In-Game scene prep function will copy this data into the In-Game
# minor scene data (0x10), which ultimately gets used.
lwz	REG_VS_SSS_DATA, -0x77C0 (r13)
addi	REG_VS_SSS_DATA, REG_VS_SSS_DATA, 1424 + 0x8   # adding 0x8 to skip past some unk stuff
mr  r3,REG_VS_SSS_DATA
addi r4,REG_MSRB_ADDR, MSRB_GAME_INFO_BLOCK    #
li  r5,0x60 + (0x24*6)  #match data + player data
branchl r12,memcpy

# Write data for left character

# Write selected character to where ScenePrep_ClassicMode function will read from
branchl r12, 0x8017eb30

lbz r4, MSRB_GAME_INFO_BLOCK + 0x60(REG_MSRB_ADDR) # load char id
stb r4, 0(r3) # write char id
lbz r4, MSRB_GAME_INFO_BLOCK + 0x63(REG_MSRB_ADDR) # load char color
stb r4, 1(r3) # write char color

li r4, 0
stb r4, 2(r3) # difficulty, unused, could maybe leave unset
li r4, 3
stb r4, 5(r3) # stocks, unused, could maybe leave unset
li r4, 0x78
stb r4, 4(r3) # name to show under char. 0x78 = char name, 0 = nametag

# Write data for right character

# Prepare to write to data used to set up right character
load r4, 0x803ddec8
lwz r4, 0xc(r4)

lbz r3, MSRB_GAME_INFO_BLOCK + 0x60 + 0x24(REG_MSRB_ADDR) # load char 2 id
stb r3, 2(r4)
li r3, 0x2121 # store empty slots for chars 2/3
sth r3, 3(r4)

# Here we write P2 color. this was done in sort of a hacky way. the PreventP2Color
# file will prevent us setting this value early from getting overwritten.
# I'm not sure what the function at line 801b364c does but it seems to always
# return zero. Ideally we would set a mem location here that would cause that
# function to return the color we want, but I couldn't figure out how
load r4, 0x80490880
lbz r3, MSRB_GAME_INFO_BLOCK + 0x63 + 0x24(REG_MSRB_ADDR) # load char 2 color
stb r3, 0x16(r4)

# Free the buffer we allocated to get match settings
mr r3, REG_MSRB_ADDR
branchl r12, HSD_Free

# Set next scene as Splash
load r4, 0x80479d30
li r3, 0x05
stb r3, 0x5(r4)

CSSSceneDecide_Exit:
restore
blr
#endregion


#region SplashScenePrep
SplashSceneData:
blrl
.long 0x01780101
.long 0x01FF2121
.long 0xFF2121EE
.long 0x0000EE00
SplashScenePrep:
.set REG_VS_SSS_DATA,31

backup

lwz	REG_VS_SSS_DATA, -0x77C0 (r13)
addi	REG_VS_SSS_DATA, REG_VS_SSS_DATA, 1424 + 0x8   # adding 0x8 to skip past some unk stuff

#Copy Splash Data
load  r3,0x80490888
bl  SplashSceneData
mflr  r4
li  r5,0x10
branchl r12,memcpy
#Modify Splash Data
load  r4,0x80490888
lbz r3, 0x60(REG_VS_SSS_DATA) # load p1 char id
stb r3,0x5(r4)
lbz r3, 0x63(REG_VS_SSS_DATA) # load char color
stb r3,0xB(r4)
lbz r3, 0x60 + 0x24(REG_VS_SSS_DATA) # load p2 char id
stb r3,0x8(r4)
lbz r3, 0x63 + 0x24(REG_VS_SSS_DATA) # load char color
stb r3,0xE(r4)

# Preload these fighters
load r4,0x80432078
lbz r3, 0x60(REG_VS_SSS_DATA) # load p1 char id
stw r3, 0x14 (r4)
lbz r3, 0x63(REG_VS_SSS_DATA) # load char color
stb r3, 0x18 (r4)
lbz r3, 0x60 + 0x24(REG_VS_SSS_DATA) # load p2 char id
stw r3, 0x1C (r4)
lbz r3, 0x63 + 0x24(REG_VS_SSS_DATA) # load char color
stb r3, 0x20 (r4)
# Preload the stage
lhz r3, 0xE (REG_VS_SSS_DATA)
stw r3, 0xC (r4)
# Queue file loads
branchl r12,0x80018254

li  r3,199
branchl r12,0x80018c2c
li  r3,4
branchl r12,0x80017700


# Load fighters' ssm files
.set REG_COUNT,20
.set REG_SSMBIT1,21
.set REG_SSMBIT2,22
.set REG_CURR,23
li	REG_COUNT, 0
mulli	r0, REG_COUNT, 36
mr REG_CURR, REG_VS_SSS_DATA
add	REG_CURR, REG_CURR, r0
li	REG_SSMBIT1, 0
li	REG_SSMBIT2, 0
CSSSceneDecide_SSMLoop:
lbz	r3, 0x0060 (REG_CURR)
extsb	r3, r3
branchl r12,0x80026E84
addi	REG_COUNT, REG_COUNT, 1
cmpwi	REG_COUNT, 6
or	REG_SSMBIT2, REG_SSMBIT2, r4
or	REG_SSMBIT1, REG_SSMBIT1, r3
addi	REG_CURR, REG_CURR, 36
blt+	 CSSSceneDecide_SSMLoop
# Load stage's ssm file
lhz r3, 0xE (REG_VS_SSS_DATA)
branchl	r12, 0x80026EBC
or	REG_SSMBIT1, r3, REG_SSMBIT1
or	REG_SSMBIT2, r4, REG_SSMBIT2
# Clear ssm queue
li	r3, 28
branchl	r12, 0x80026F2C
# Queue ssms
addi	r6, REG_SSMBIT2, 0
addi	r5, REG_SSMBIT1, 0
li	r3, 12
branchl r12, 0x8002702C
# set to load
branchl r12, 0x80027168

restore
blr
#endregion

Injection_Exit:
#Exit Scene
  restore
  li  r3,ExitSceneID
  stb r3,0x0(r30)
  li	r31, 0
