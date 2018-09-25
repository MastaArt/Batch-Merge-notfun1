/*  
[INFO] 

NAME = Batch Merge
VERSION = 1.0.0
AUTHOR = Vasily Lukyanenko
DEV = 3DGROUND
CUSTOMER = Andrew Andreyuk
SKYPE = notfun1
HELP = 

[INSTALL]

MACRO=BatchMergeNotfun1
CAT=3DGROUND
TEXT=Batch Merge
ICON=#("PhysX_Main", 31)

[1.0.0]

* First release =

[ABOUT]

Merge multiple *.max files and arrange=

[TEST]

[SCRIPT]
*/	


try(closeRolloutFloater rBatchMerge)catch()
global rBatchMerge = newRolloutFloater "Batch Merge" 280 510

global _STEP1
global BitmapTypes = #(Bitmaptexture, CoronaBitmap)

fn trim s c: " " = trimRight (trimLeft s c) c

fn getScriptInfo s releaseInfo: "" =
(		
	if(releaseInfo != "") do
	(
		r = getINISetting s releaseInfo
		return r
	)
	
	v = getINISetting s "INFO" "VERSION"
	a = getINISetting s "INFO" "AUTHOR"
	n = getINISetting s "INFO" "NAME"
	o = getINISetting s "ABOUT"
	c = getINISetting s "INFO" "DEV"
	h = getINISetting s "INFO" "HELP"
	
	r = for i in (getINISetting s) where i != "ABOUT" and i != "SCRIPT" and i != "COPY" collect i
	
	return #(n, a, v, o, r, c, h)
)

fn showTooltip c t =
(
	toolTip = dotnetobject "System.Windows.Forms.ToolTip"
	toolTip.SetToolTip c t   
	--toolTip.Active = true    
	toolTip.isBalloon = true
	toolTip.InitialDelay = 100
	toolTip.AutoPopDelay = 500
	toolTip.ReshowDelay = 50
	toolTip.ToolTipTitle = "Warning!"
	toolTip.Show t c 3000	
	toolTip.ToolTipIcon = (dotnetclass "System.Windows.Forms.ToolTipIcon").Warning
)

fn useSettings k v type:#get =
(
	f = getThisScriptFilename() + ".ini"
	case type of
	(
		#set: setIniSetting f "SETTINGS" k v
		default: getIniSetting f "SETTINGS" k
	)
)

fn freezeUi =
(
  	source = ""
  	source += "using System;\n"
  	source += "using System.Runtime.InteropServices;\n"
  	source += "class WindowsGhosting\n"
  	source += "{\n"
  	source += " [DllImport(\"user32.dll\")]\n"
  	source += " public static extern void DisableProcessWindowsGhosting();\n"
  	source += "}\n"
  
  	csharpProvider = dotnetobject "Microsoft.CSharp.CSharpCodeProvider"
  	compilerParams = dotnetobject "System.CodeDom.Compiler.CompilerParameters"
  
  	compilerParams.GenerateInMemory = on
  	compilerResults = csharpProvider.CompileAssemblyFromSource compilerParams #(source)
  
  	assembly = compilerResults.CompiledAssembly
  	windowsGhosting = assembly.CreateInstance "WindowsGhosting"
  	windowsGhosting.DisableProcessWindowsGhosting()
)

rollout _STEP1 ""
(
	group "Files List" (
		listbox lbxFilesList "" height: 20
		button btnAdd "+ Add" width: 100 height: 26 across: 2 tooltip: "Add multiiple files to list"
		button btnRemove "- Remove" width: 100 height: 26 tooltip: "Remove files from list one by one" 
	)
	
	group "Settings" (
		spinner spnDistance "Distance between models: " range: [0.1, 1e9, (units.decodeValue  "1m")] type: #worldunits fieldwidth: 70 align: #left
		checkbox cbxGroupObjects "Group merged objects" checked: true
	)
	
	button btnMergeAllFiles "Merge All Files" width: 250 height: 36 offset: [0, 8]
	
	global filesList = #()
	
	fn getOpenMaxFiles = 
	(
		f = #()
		
		imageDialog = dotNetObject "System.Windows.Forms.OpenFileDialog" 
		imageDialog.title = "Select Pictures"
		imageDialog.Multiselect = true
		imageDialog.Filter = "3ds max (*.max)|*.max"
		imageDialog.FilterIndex = 1
		
		result = imageDialog.showDialog() 
		result.ToString() 
		result.Equals result.OK 
		result.Equals result.Cancel 
		
		f = imageDialog.fileNames 
		 
		return f
	)
	
	fn updateList = (
		ff = for f in filesList collect (getFileNameFile f)
		lbxFilesList.items = ff
	)
	
	fn modalConfirmClear = (
		
		global _returnConfirmClear = #none
		try(destroyDialog rrCodalConfirmClear)catch()
		
		rollout rrCodalConfirmClear "Confirm?"  (
			label lblTxt "Do you really want to remove?" offset: [0, 15] align: #left
			button btnRemoveItem "Remove Item" across: 3 align: #left width: 100 height: 36 offset: [0, 15]
			button btnRemoveAll "Remove All Items" align: #left width: 100 height: 36 offset: [0, 15]
			button btnRemoveNone "Cancel" align: #left width: 100 height: 36 offset: [0, 15]
		
		
			on btnRemoveItem pressed do (
				_returnConfirmClear = #item
				try(destroyDialog rrCodalConfirmClear)catch()
			)
			on btnRemoveAll pressed do (
				_returnConfirmClear = #all
				try(destroyDialog rrCodalConfirmClear)catch()
			)
			on btnRemoveNone pressed do (
				_returnConfirmClear = #none
				try(destroyDialog rrCodalConfirmClear)catch()				
			)
		)
		
		createDialog rrCodalConfirmClear 350 110 modal: true 
		
		return _returnConfirmClear
	)
	
	fn clearAllList = (
		if(filesList.count == 0) do return messageBox "No items for delete!" title: "Warning!"
		
		q = queryBox "Do you really want to clear all items?" title: "Confirm?"		
		if(not q) do return false
		
		filesList = #()
		updateList()
	)
	
	fn clarItemList = (
		i = lbxFilesList.selection 
		if(i == 0) do return messageBox "No items for delete!" title: "Warning!"
		
		deleteItem filesList i
		
		updateList()
	)
	
	fn mergeAndProcess f nn = (
		mergeMAXFile f #select #skipDups #useSceneMtlDups quiet: true
		
		if(selection.count == 0) do return false
		
		g = group selection name: (getFileNameFile f)
		select g
						
		selection.pivot = [0,0,0]
		selection.pos = [0,0,0]
		g.pos.x = (nn as float * spnDistance.value) - spnDistance.value
		
		if(not cbxGroupObjects.checked) do ungroup g
	)
	
	on btnAdd pressed do (				
		f = getOpenMaxFiles()
		if(f == undefined) do return false
		
		join filesList f
		filesList = makeUniqueArray filesList
		
		updateList()
	)
	
	on btnRemove pressed do (
		r = modalConfirmClear()
		
		case r of (
			#all: clearAllList()
			#item: clarItemList()
			default: #none
		)
	)
		
	on btnMergeAllFiles pressed do (
		if(filesList.count == 0) do return messageBox "Please add files to list first!" title: "Error!"
		
		--resetMaxFile()
		
		for c in 1 to filesList.count where (doesFileExist filesList[c]) do mergeAndProcess filesList[c] c
	)
)

rollout _rAbout "About" 
(
	label lblName "" 
	label lblVer "" 
	
	label lblAuthor "" height: 30
	label lblCopy ""  height: 30
	
	local c = color 200 200 200 
	hyperLink href1 "http://3dground.net/" address: "http://3dground.net/" align: #center hoverColor: c visitedColor: c offset: [0, 20]
	
	on _rAbout open do
	(		
		i = getScriptInfo (getThisScriptFilename())
			
		lblName.caption = i[1]
		lblAuthor.caption = i[2]
		lblVer.caption = i[3]
		lblCopy.caption = i[6]
	)
)

addRollout _STEP1 rBatchMerge border: false
addRollout _rAbout rBatchMerge rolledUp:true