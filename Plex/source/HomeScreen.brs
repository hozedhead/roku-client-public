'*****************************************************************
'**  Home screen: the entry display of the application
'**
'*****************************************************************

Function createHomeScreen(viewController) As Object
    obj = CreateObject("roAssociativeArray")
    port=CreateObject("roMessagePort")
    screen = CreateObject("roPosterScreen")
    screen.SetMessagePort(port)

    ' Standard properties for all our Screen types
    obj.Item = invalid
    obj.Screen = screen
    obj.ViewController = viewController

    obj.Show = showHomeScreen
    obj.Refresh = refreshHomeScreen

    obj.ShowSection = displaySection
    obj.ShowPreferencesDialog = showPreferencesDialog
    obj.ShowTweaksDialog = showTweaksDialog
    obj.ShowMediaServersDialog = showMediaServersDialog
    obj.ShowManualServerDialog = showManualServerDialog
    obj.ShowFivePointOneDialog = showFivePointOneDialog
    obj.ShowQualityDialog = showQualityDialog
    obj.ShowH264Dialog = showH264Dialog
    obj.ShowChannelsAndSearchDialog = showChannelsAndSearchDialog

    obj.Servers = []

    screen.SetListStyle("flat-category")
    screen.setListDisplayMode("zoom-to-fill")

    return obj
End Function

Function refreshHomeScreen()
    print "About to show home screen"
    m.Servers = PlexMediaServers()
    displayServerName = m.Servers.count() > 1
    m.sectionList = CreateObject("roArray", 10, true)  
    for each server in m.Servers
    	sections = server.GetHomePageContent()
    	for each section in sections
    		if displayServerName then
                    section.ShortDescriptionLine2 = server.name
    		endif
    		m.sectionList.Push(section)
    	end for
    end for
	
    '** Prefs
    prefs = CreateObject("roAssociativeArray")
    prefs.server = m
    prefs.sourceUrl = ""
    prefs.ContentType = "series"
    prefs.Key = "prefs"
    prefs.Title = "Preferences"
    prefs.ShortDescriptionLine1 = "Preferences"
    prefs.SDPosterURL = "file://pkg:/images/prefs.jpg"
    prefs.HDPosterURL = "file://pkg:/images/prefs.jpg"
    m.sectionList.Push(prefs)
	
	
    m.Screen.SetContentList(m.sectionList)
    m.Screen.SetFocusedListItem(0)
End Function

Function showHomeScreen() As Integer
    m.Refresh()
    m.Screen.Show()

    while true
        msg = wait(0, m.Screen.GetMessagePort())
        if type(msg) = "roPosterScreenEvent" then
            print "showHomeScreen | msg = "; msg.GetMessage() " | index = "; msg.GetIndex()
            if msg.isListFocused() then
                print "list focused | index = "; msg.GetIndex(); " | category = "; m.curCategory
            else if msg.isListItemSelected() then
                print "list item selected | index = "; msg.GetIndex()
                section = m.sectionList[msg.GetIndex()]
                print "section selected ";section.Title
                m.ShowSection(section)
            else if msg.isScreenClosed() then
                return -1
            end if
        end If
    end while

    return 0

End Function

Function displaySection(section As Object) As Dynamic
    if validateParam(section, "roAssociativeArray", "displaySection") = false return -1
    
    if section.key = "globalsearch" then
    	queryString = getQueryString()
    	if len(queryString) > 0 then
    		screen = preShowSearchPosterScreen(section.Title, "")
    		showSearchPosterScreen(screen, section.server, queryString)
    		'showSearchGridScreen(section.server, queryString)
    	end if
    else if section.key = "prefs" then
        m.ShowPreferencesDialog()
    else
        ' TODO: Don't muck with the contentType here
        section.contentType = "section"
        screen = m.ViewController.CreateScreenForItem(section, invalid, [section.server.name, section.Title], false)
        if section.key = "apps" then screen.SetStyle("flat-square")
        screen.Show()
    endif
    return 0
End Function

Function showPreferencesDialog()

	port = CreateObject("roMessagePort") 
	dialog = CreateObject("roMessageDialog") 
	dialog.SetMessagePort(port)
	dialog.SetMenuTopLeft(true)
	dialog.EnableBackButton(false)

    manifest = ReadAsciiFile("pkg:/manifest")
    lines = manifest.Tokenize(chr(10))
    aa = {}
    for each line in lines
        entry = line.Tokenize("=")
        aa.AddReplace(entry[0],entry[1])
    end for

    dialog.SetTitle("Preferences v."+aa["version"])
    dialog.AddButton(1, "Plex Media Servers")
    dialog.AddButton(2, "Quality")
    dialog.AddButton(3, "Tweaks")
    dialog.AddButton(4, "Close Preferences")
    dialog.Show()
    while true 
        msg = wait(0, dialog.GetMessagePort()) 
        if type(msg) = "roMessageDialogEvent"
            if msg.isScreenClosed() then
                dialog.close()
                exit while
            else if msg.isButtonPressed() then
                if msg.getIndex() = 1 then
                    m.ShowMediaServersDialog()
                    dialog.close()
                    m.Refresh()
                else if msg.getIndex() = 2 then
                    m.ShowQualityDialog()
                else if msg.getIndex() = 3 then
                    m.ShowTweaksDialog()
                else if msg.getIndex() = 4 then
                    dialog.close()
                end if
            end if 
        end if
    end while
End Function

Function showTweaksDialog()
    port = CreateObject("roMessagePort") 
    dialog = CreateObject("roMessageDialog") 
    dialog.SetMessagePort(port)
    dialog.SetMenuTopLeft(true)
    dialog.EnableBackButton(false)
    dialog.SetTitle("Tweaks")
    dialog.AddButton(1, "H264 Levels")
    dialog.AddButton(2, "Channels and Search")
    dialog.AddButton(3, "5.1 Support")
    'dialog.AddButton(4, "SRT Subtitles")
    dialog.AddButton(5, "Close Tweaks")
    dialog.Show()
    while true 
        msg = wait(0, dialog.GetMessagePort()) 
        if type(msg) = "roMessageDialogEvent"
            if msg.isScreenClosed() then
                dialog.close()
                exit while
            else if msg.isButtonPressed() then
                print "Button pressed:: msg.getIndex() = ";msg.getIndex()
                if msg.getIndex() = 1 then
                    m.ShowH264Dialog()
                else if msg.getIndex() = 2 then
                    m.ShowChannelsAndSearchDialog()
                else if msg.getIndex() = 3 then
                    m.ShowFivePointOneDialog()
                'else if msg.getIndex() = 4 then
                    'SRTSubtitles()
                else if msg.getIndex() = 5 then
                    dialog.close()
                end if
            end if 
        end if
    end while
End Function


Function showMediaServersDialog()
	port = CreateObject("roMessagePort") 
	dialog = CreateObject("roMessageDialog") 
	dialog.SetMessagePort(port)
	dialog.SetMenuTopLeft(true)
	dialog.EnableBackButton(false)
	dialog.SetTitle("Plex Media Servers") 
	dialog.setText("Manage Plex Media Servers")
	
	dialog.AddButton(1, "Close manage servers dialog")
	dialog.AddButton(2, "Add server manually")
	dialog.AddButton(3, "Discover servers")
	dialog.AddButton(4, "Remove all servers")
	
	fixedSections = 4
	buttonCount = fixedSections + 1
	for each server in m.Servers
		title = "Remove "+server.name + " ("+server.serverUrl+")"
		dialog.AddButton(buttonCount, title)
		buttonCount = buttonCount + 1
	next
	
	dialog.Show()
	while true 
            msg = wait(0, dialog.GetMessagePort()) 
            if type(msg) = "roMessageDialogEvent"
                if msg.isScreenClosed() then
                    print "Manage servers closed event"
                    dialog.close()
                    exit while
                else if msg.isButtonPressed() then
                    if msg.getIndex() = 1 then
                        print "Closing dialog"
                    else if msg.getIndex() = 2 then
                        m.ShowManualServerDialog()

                        ' UPDATE: I'm not seeing this problem, but I'm loathe to remove such a specific workaround...
                        ' Not sure why this is needed here. It appears that exiting the keyboard
                        ' dialog removes all dialogs then locks up screen. Redrawing the home screen
                        ' works around it.
                        'screen=preShowHomeScreen("", "")
                        'showHomeScreen(screen, PlexMediaServers())
                    else if msg.getIndex() = 3 then
                        DiscoverPlexMediaServers()
                    else if msg.getIndex() = 4 then
                        RemoveAllServers()
                    else
                        RemoveServer(msg.getIndex()-(fixedSections+1))
                    end if
                    dialog.close()
                end if 
            end if
	end while
End Function

Sub showManualServerDialog()
    port = CreateObject("roMessagePort") 
    keyb = CreateObject("roKeyboardScreen")    
    keyb.SetMessagePort(port)
    keyb.SetDisplayText("Enter Host Name or IP without http:// or :32400")
    keyb.SetMaxLength(80)
    keyb.AddButton(1, "Done") 
    keyb.AddButton(2, "Close")
    keyb.setText("")
    keyb.Show()
    while true 
        msg = wait(0, keyb.GetMessagePort()) 
        if type(msg) = "roKeyboardScreenEvent" then
            if msg.isScreenClosed() then
                print "Exiting keyboard dialog screen"
                return
            else if msg.isButtonPressed() then
                if msg.getIndex() = 1 then
                    AddUnnamedServer(keyb.GetText())
                end if
                return
            end if 
        end if
    end while
End Sub

Function showFivePointOneDialog()
	port = CreateObject("roMessagePort") 
	dialog = CreateObject("roMessageDialog") 
	dialog.SetMessagePort(port)
	dialog.SetMenuTopLeft(true)
	dialog.EnableBackButton(false)
	dialog.SetTitle("5.1 Support") 
	dialog.setText("Bear in mind that 5.1 support only works on the Roku 2 (4.x) firmware, and this setting will be ignored if that firmware is not detected.")

	buttonCommands = CreateObject("roAssociativeArray")

	fiveone = CreateObject("roArray", 6 , true)
	fiveone.Push("Enabled")
	fiveone.Push("Disabled")

	if not(RegExists("fivepointone", "preferences")) then
		RegWrite("fivepointone", "1", "preferences")
	end if
	current = RegRead("fivepointone", "preferences")

	buttonCount = 1
	for each value in fiveone
		title = value
		if current = value then
			title = "> "+title
		end if
		if current = (buttonCount).tostr() then
			title = "> "+title
		end if
		dialog.AddButton(buttonCount, title)
		buttonCount = buttonCount + 1
	next
	
	dialog.Show()
	while true 
		msg = wait(0, dialog.GetMessagePort()) 
		if type(msg) = "roMessageDialogEvent"
			if msg.isScreenClosed() then
				dialog.close()
				exit while
			else if msg.isButtonPressed() then
        		fiveone = (msg.getIndex()).tostr()
        		print "Set 5.1 support to ";fiveone
        		RegWrite("fivepointone", fiveone, "preferences")
				dialog.close()
			end if 
		end if
	end while
End Function

Function showQualityDialog()
	port = CreateObject("roMessagePort") 
	dialog = CreateObject("roMessageDialog") 
	dialog.SetMessagePort(port)
	dialog.SetMenuTopLeft(true)
	dialog.EnableBackButton(false)
	dialog.SetTitle("Quality Settings") 
	dialog.setText("Choose quality setting. Higher settings produce better video quality but require more network bandwidth.")
	buttonCommands = CreateObject("roAssociativeArray")
	qualities = CreateObject("roArray", 6 , true)
	
	qualities.Push("720 kbps, 320p") 'N=1, Q=4
	qualities.Push("1.5 Mbps, 480p") 'N=2, Q=5
	qualities.Push("2.0 Mbps, 720p") 'N=3, Q=6
	qualities.Push("3.0 Mbps, 720p") 'N=4, Q=7
	qualities.Push("4.0 Mbps, 720p") 'N=5, Q=8
	qualities.Push("8.0 Mbps, 1080p") 'N=6, Q=9
	
	if not(RegExists("quality", "preferences")) then
		RegWrite("quality", "7", "preferences")
	end if
	current = RegRead("quality", "preferences")
	
	buttonCount = 1
	for each quality in qualities
		title = quality
		if current = quality then
			title = "> "+title
		end if
		if current = (3 + buttonCount).tostr() then
			title = "> "+title
		end if
		dialog.AddButton(buttonCount, title)
		buttonCount = buttonCount + 1
	next
	
	dialog.Show()
	while true 
		msg = wait(0, dialog.GetMessagePort()) 
		if type(msg) = "roMessageDialogEvent"
			if msg.isScreenClosed() then
				dialog.close()
				exit while
			else if msg.isButtonPressed() then
				if msg.getIndex() = 1 then
					quality = "Auto"
				else
        			quality = (3 + msg.getIndex()).tostr()
        		end if
        		print "Set selected quality to ";quality
        		RegWrite("quality", quality, "preferences")
				dialog.close()
			end if 
		end if
	end while
End Function

Function showH264Dialog()
	port = CreateObject("roMessagePort") 
	dialog = CreateObject("roMessageDialog") 
	dialog.SetMessagePort(port)
	dialog.SetMenuTopLeft(true)
	dialog.EnableBackButton(false)
	dialog.SetTitle("H264 Level") 
	dialog.setText("Use specific H264 level. Only 4.0 is officially supported.")
	buttonCommands = CreateObject("roAssociativeArray")
	levels = CreateObject("roArray", 5 , true)
	
	levels.Push("Level 4.0 (Supported)") 'N=1
	levels.Push("Level 4.1") 'N=2
	levels.Push("Level 4.2") 'N=3
	levels.Push("Level 5.0") 'N=4
	levels.Push("Level 5.1") 'N=5
	
	if not(RegExists("level", "preferences")) then
		RegWrite("level", "40", "preferences")
	end if

	if RegRead("level", "preferences") = "40" then
		current = "Level 4.0 (Default)"
	else if RegRead("level", "preferences") = "41" then
		current = "Level 4.1"
	else if RegRead("level", "preferences") = "42" then
		current = "Level 4.2"
	else if RegRead("level", "preferences") = "50" then
		current = "Level 5.0"
	else if RegRead("level", "preferences") = "51" then
		current = "Level 5.1"
	end if
	buttonCount = 1
	for each level in levels
		title = level
		if current = level then
			title = "> "+title
		end if
		dialog.AddButton(buttonCount, title)
		buttonCount = buttonCount + 1
	next
	
	dialog.Show()
	while true 
		msg = wait(0, dialog.GetMessagePort()) 
		if type(msg) = "roMessageDialogEvent"
			if msg.isScreenClosed() then
				dialog.close()
				exit while
			else if msg.isButtonPressed() then
				if msg.getIndex() = 1 then
					level = "40"
				else if msg.getIndex() = 2 then
					level = "41"
				else if msg.getIndex() = 3 then
					level = "42"
				else if msg.getIndex() = 4 then
					level = "50"
				else if msg.getIndex() = 5 then
					level = "51"
				end if
        		end if
        		print "Set selected level to ";level
        		RegWrite("level", level, "preferences")
				dialog.close()
			end if 
	end while
End Function

Function showChannelsAndSearchDialog()
	port = CreateObject("roMessagePort") 
	dialog = CreateObject("roMessageDialog") 
	dialog.SetMessagePort(port)
	dialog.SetMenuTopLeft(true)
	dialog.EnableBackButton(false)
	dialog.SetTitle("Channels and Search") 
	dialog.setText("Enable/Disable 'Channel' and 'Search' options showing up on the main screen.")
	buttonCommands = CreateObject("roAssociativeArray")
	options = CreateObject("roArray", 2 , true)
	
	options.Push("Enabled (Default)") 'N=1
	options.Push("Disabled") 'N=2

	if not(RegExists("ChannelsAndSearch", "preferences")) then
		RegWrite("ChannelsAndSearch", "1", "preferences")
	end if
	
	if RegRead("ChannelsAndSearch", "preferences") = "2" then
		current = "Disabled"
        else
		current = "Enabled (Default)"
	end if
	buttonCount = 1
	for each option in options
		title = option
		if current = option then
			title = "> "+title
		end if
		dialog.AddButton(buttonCount, title)
		buttonCount = buttonCount + 1
	next
	
	dialog.Show()
	while true 
            msg = wait(0, dialog.GetMessagePort()) 
            if type(msg) = "roMessageDialogEvent"
                if msg.isScreenClosed() then
                    dialog.close()
                    exit while
                else if msg.isButtonPressed() then
                    option = msg.getIndex().tostr()	
                    RegWrite("ChannelsAndSearch", option, "preferences")
                    dialog.Close()
                    m.Refresh()
                end if
            end if 
	end while
End Function

Function getQueryString() As String
	queryString = ""
	
	searchHistory = CreateObject("roSearchHistory")
	port = CreateObject("roMessagePort") 
	searchScreen = CreateObject("roSearchScreen") 
	searchScreen.SetMessagePort(port)
	searchScreen.SetSearchTerms(searchHistory.GetAsArray())
	searchScreen.show()
	done = false
	while done = false
		msg = wait(0, searchScreen.getMessagePort())
		if type(msg) = "roSearchScreenEvent" then
			if msg.isFullResult() then
				queryString = msg.getMessage()
				if len(queryString) > 0 then
					searchHistory.Push(queryString)
				end if
				done = true
			else if msg.isScreenClosed() then
				done = true
			end if
		end if
	end while
	print "Query string:";queryString
	return queryString
End Function
