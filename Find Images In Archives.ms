/*  
[INFO] 
NAME=Find Images In Archives
VERSION=1.0.0
AUTHOR=MastaMan
DEV=https://3dground.net
HELP=
CLIENT=Eugen Zharnikov

[ABOUT]
Script for bulk find images in archives=

[1.0.0]
* Initial release =

[FILES]
extract.bat=
recursive-find-archives.bat=
7za.exe=

[SCRIPT]
*/

struct '@' (
	currScript = getThisScriptFileName(),
	name = getFilenameFile currScript,
	pth = getFileNamePath currScript,
	ini = pth +  sysinfo.username + "@" + sysinfo.computername + ".ini",
	--ini = (getThisScriptFileName()) + ".ini",
	sec = name,
	
	fn trim s tag: "" = (
		s as string
		return (trimLeft (trimRight s tag) tag)
	),
	
	fn add k v sec: "" = (
		if (sec == "") do sec = this.sec
		if (v == undefined) do v = ""
		setIniSetting this.ini sec k (v as string)
	),
	
	fn get k sec: "" type: #string = (
		if (sec == "") do sec = this.sec
		
		if (k == "") do return getINISetting this.ini sec
		
		local v = getIniSetting this.ini sec k
		
		case type of (
			#bool_true: return if (v == "true") then true else false
			#bool_false: return if (v == "false") then false else true
			#int: return try (v as integer) catch(0)
		)
		
		return v
	),
	
	fn del k sec: "" = (
		if (sec == "") do sec = this.sec
		delIniSetting ini sec k
	),	
	
	fn delSec s = (
		delIniSetting ini s
	)
)

global '*' = '@'()	


try(closeRolloutFloater floaterBatchFindImagesInArchives) catch()
global floaterBatchFindImagesInArchives = newRolloutFloater "Find Images In Archives" 300 300

rollout _rBatchFindImagesInArchives "Find Images In Archives" category: 1 (
	group "Folder With Archives" (
		edittext edtInputPath "" readonly: true across: 2 align: #left fieldwidth: 215 height: 22		
		button btnSearchInputPath "..." width: 35 height: 24  align: #right offset: [0, -1]	
	)
	
	button btnScanFolder "Scan Folder" width: 260 offset: [0, 10]
	button btnBatchProcess "Batch Process" height: 36 width: 260 offset: [0, 10]
	checkbox cbxIgnoreProcessed "Ignore Processed Archives" checked: true
	
	label lblStatus "" align: #left offset: [0, 4]
	progressBar pbProgress color: green height: 5 offset: [0, 4]
	
	fn boost = if (((maxVersion())[1] / 1000) >= 13) do windows.processPostedMessages() 
	
	fn loadSettings = (
		edtInputPath.text = '*'.get "tnt_path"		
		cbxIgnoreProcessed.checked = '*'.get "cbxIgnoreProcessed" type: #bool_false
	)
	
	fn recursiveFindArchives = (
		local currentPath = getFileNamePath (getThisScriptFileName())
		
		local p = edtInputPath.text
		local args = p + ";" + "test"
		args = substituteString args "/" @"\"
		
		local cmd = "recursive-find-archives.bat \"" +  args + "\""
		
		local curDir = sysInfo.currentDir
		sysInfo.currentDir = currentPath
		
		hiddenDosCommand cmd exitCode: &exitcode donotwait: false
		
		sysInfo.currentDir = curDir
	)
	
	fn extractZip f o = (
		local currentPath = getFileNamePath (getThisScriptFileName())
		
        if (f == undefined or not doesFileExist f) do return false
		
		local args = f + ";" + o
		args = substituteString args "/" @"\"
		
		local cmd = "extract.bat \"" +  args + "\""
		
		local curDir = sysInfo.currentDir
		sysInfo.currentDir = currentPath
		print cmd
		hiddenDosCommand cmd exitCode: &exitcode donotwait: false
		
		sysInfo.currentDir = curDir
    )
	
	fn getFilesRecursive r pattern: "*.*" = (
        local dd = getDirectories (r + "/*")
        local ff = getFiles (r + "/" + pattern)
        for i in dd do join ff (getFilesRecursive i pattern: pattern)
        
        return ff
    )
	
	fn isMatch s pattern: #() = (
		for p in pattern do (
			if (MatchPattern s pattern: p ignoreCase: true) do return true
		)
		
		return false
	)
	
	fn getProcessedIni = (
		local s = edtInputPath.text
		s = substituteString s @"\" "_"
		s = substituteString s @":" "_"
		s = substituteString s @"." "_"
		s = substituteString s @"#" "_"
		
		local p = getFilenamePath (getThisScriptFilename())
		
		return p +"processed_" + s + ".ini"
	)
	
	fn setProcessed f = (
		local ini = getProcessedIni()
		setINISetting ini "FILES" f "true"
	)
	
	fn getProcessed f = (
		local ini = getProcessedIni()
		return (getINISetting ini "FILES" f) == "true"
	)
	
	fn getProcessedCnt = (
		local ini = getProcessedIni()
		return (getINISetting ini "FILES").count as string
	)
	
	fn getArchives = (
		local ini = edtInputPath.text + "files.ini"
		return getINISetting ini "FILES"
	)
	
	fn findAndCopyImages p types: #("*.jpg", "*.jpeg", "*.png") = (
		local root = edtInputPath.text
		local outDir = root + @"images\"
		local badPatterns = #(
			@"*\resources\*", 
			@"*\renders\*", 
			@"*\renderoutput\*", 
			@"*\render\*", 
			@"*\maps\*", 
			@"*\PIX\*",
			@"*.MultiMatteElemen*",
			@"*Mask*",
			@"*.RGB_*",
			@"*.Alpha*",
			@"*.VRay*"
		)
		
		makeDir outDir all: true
		
		local files = getFilesRecursive p
		
		for f in files do (
			local fname = filenameFromPath f
			
			if (not isMatch f pattern: types) do continue
			local isRoot = (substituteString f root "") == fname
			if (not isRoot and isMatch f pattern: badPatterns) do continue
			
			local new = outDir + (timeStamp() as string) + "___" + fname
			
			copyFile f new
		)
	)
	
	fn rmDir d = (
		local cmd = "timeout /t 5 /nobreak > nul&rmdir /S /Q \"" + d + "\""
		HiddenDOSCommand cmd donotwait: true
	)
	
	fn batchProcess = (
		local p = edtInputPath.text
		if (p == "") do return messageBox "Please select folder" title: "Warning!"
		local aa = getArchives()
		if (aa.count == 0) do return messageBox "Not found archives in folder!\nPlease run Rescan process!" title: "Warning!"
		
		for i in 1 to aa.count do (
			local a = aa[i]
			local n = getFilenameFile a
			local d = getFilenamePath a
			local ext = getFilenameType a
			local o = d + n + (substituteString ext "." "_") + @"\"
			
			if (cbxIgnoreProcessed.checked and getProcessed a) do continue
			
			extractZip a o
			
			findAndCopyImages o
				
			rmDir o
			
			setProcessed a
			lblStatus.caption = "Processed " + (i as string) + "/" + (aa.count as string)
			
			pbProgress.value = 100 * i / aa.count
			boost()	
		)		
	)
	
	
	
	fn updateUI = (
		local ini = edtInputPath.text + "files.ini"
		
		if (not doesFileExist ini) then (
			lblStatus.caption = "Need scan this directory first!"
			btnBatchProcess.enabled = false
			btnScanFolder.caption = "Scan Folder"
		) else (
			local c = ((getArchives()).count) as string
			lblStatus.caption = "Ready to process " + c + " files"
			if (cbxIgnoreProcessed.checked) do (
				lblStatus.caption += " | (Ignore: " + getProcessedCnt() + ")"
			)
			
			btnBatchProcess.enabled = true
			btnScanFolder.caption = "Rescan Folder"
		)		
	)
	
	on btnScanFolder pressed do (
		recursiveFindArchives()
		updateUI()
	)
	on btnBatchProcess pressed do batchProcess()
	
	on btnSearchInputPath pressed do (
		local d = '*'.get "tnt_path"
		local p = getSavePath initialDir: d
		
		if (p == undefined) do return false
		p = (trimRight p @"\") + @"\"
		
		edtInputPath.text = p
		'*'.add "tnt_path" p
		
		loadSettings()
		updateUI()
	)
	
	on _rBatchFindImagesInArchives open do (
		loadSettings()
		updateUI()
	)
	
	on cbxIgnoreProcessed changed v do '*'.add "cbxIgnoreProcessed" v
)

rollout _rAboutFindImagesInArchives "About" category: 999 (
		group "Description" (
			dotNetControl edtDescription "System.Windows.Forms.Textbox" align:#center height: 60
		)
		
		label lblDummy1 ""
		
		label lblName "" 
		label lblVer ""
		label lblClient ""
		
		label lblDummy2 ""
		
		label lblAuthor ""
		hyperlink lblCopy ""  align: #center
		
		label lblDummy3 ""
		
		timer tmrRestart "" active: false interval: 300
			
		fn downloadFile url dl = (
			deleteFile dl
			w = dotNetObject "System.Net.WebClient"			
			try(
				spm = dotNetClass "System.Net.ServicePointManager"
				spm.SecurityProtocol = spm.SecurityProtocol.TLS12				
				w.DownloadFile (url + "?time=" + timestamp() as string) dl				
			) catch(
				return false
			)
			
			return true
		)
		
		fn bgUpdate = (
			local url = "https://raw.githubusercontent.com/MastaArt/GC-Find-Images-In-Archives/main/"
			local main = url + "Find Images In Archives.ms"
			
			local this = getThisScriptFileName()
			local p = getFileNamePath (getThisScriptFileName())
			local dl = this + ".tmp"
			local r = downloadFile main dl
			if(not r or not doesFileExist dl) do return print "Can't download updates!"
			local vn = getIniSetting dl "INFO" "VERSION"
			local vo = getIniSetting this "INFO" "VERSION"
			local additionalFiles = getIniSetting dl "FILES"
			
			if(vn > vo) do (
				deleteFile this
				renameFile dl this
				
				for n in additionalFiles do (
					local s = getIniSetting dl "FILES" n
					if (s == "") do downloadFile (url + n) (p + n)
					if (s == "deleted") do deleteFile (p + n)
				)
				
				tmrRestart.active = true
			)
			
			deleteFile dl
		)
		
		fn updateWorker = (
			m = dotnetobject "CSharpUtilities.SynchronizingBackgroundWorker"
			m.WorkerSupportsCancellation = true 
			m.CancelAsync() 
			dotNet.addEventHandler m "DoWork" bgUpdate
			m.RunWorkerAsync()	
		)
		
		fn getScriptInfo s releaseInfo: "" =  (
			if(releaseInfo != "") do (
				local r = getINISetting s releaseInfo
				return r
			)
			
			local v = getINISetting s "INFO" "VERSION"
			local a = getINISetting s "INFO" "AUTHOR"
			local n = getINISetting s "INFO" "NAME"
			local o = ""
			for i in (getINISetting s "ABOUT") do o += i + "\r\n"
			local d = getINISetting s "INFO" "DEV"
			local h = getINISetting s "INFO" "HELP"
			local c = getINISetting s "INFO" "CLIENT"
			
			struct data (version, author, name, description, developer, client, help, releases)
			
			local r = for i in (getINISetting s) where (i != "ABOUT" and i != "SCRIPT" and i != "COPY") collect i
			
			return (data version: v author: a name: n description: o developer: d client: c help: h releases: r)
		)
		
		on tmrRestart tick do (
			this = getThisScriptFileName()
			try(fileIn this) catch()
			vo = getIniSetting this "INFO" "VERSION"
			m = ("Script updated to version " + vo + "!\n\n\n")
			for c in (getIniSetting this vo) do (
				m += c + "\n"
			)
			
			--messageBox m title: "Success!" beep: false
			print "---UPDATED---"
			print m
			tmrRestart.active = false
		)

		on _rAboutFindImagesInArchives open do (
			edtDescription.MultiLine = true
			edtDescription.WordWrap = true
			edtDescription.ReadOnly = true
			edtDescription.BorderStyle = (dotNetClass "System.Windows.Forms.BorderStyle").FixedSingle
			
			
			local i = getScriptInfo (getThisScriptFilename())
			
			lblName.caption = i.name
			lblAuthor.caption = i.author
			lblVer.caption = i.version
			lblCopy.address = lblCopy.caption = i.developer
			lblClient.caption = i.client
			edtDescription.text = i.description
			
			try (floaterBatchFindImagesInArchives.title = i.name + " " + i.version) catch()
			try (_rGCAutoModeration_Main.title = i.name + " v" +  i.version) catch()
			
			updateWorker()
			
			local x = '*'.get "x"
			local y = '*'.get "y"
			
			if (x != "" and y != "") do (
				x = x as integer
				y = y as integer
				floaterBatchFindImagesInArchives.pos = [x, y] 
			)		
		)
		
		on _rAboutFindImagesInArchives close do (
			local p = floaterBatchFindImagesInArchives.pos
			
			'*'.add "x" p.x
			'*'.add "y" p.y
		)	
	)

addRollout _rBatchFindImagesInArchives floaterBatchFindImagesInArchives rolledUp: false border: false
addRollout _rAboutFindImagesInArchives floaterBatchFindImagesInArchives rolledUp: true