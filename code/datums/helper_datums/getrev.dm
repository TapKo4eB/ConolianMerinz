/datum/getrev
	var/commit  // git rev-parse HEAD
	var/date
	var/origindevcommit  // git rev-parse origin/dev
	var/list/testmerge = list()

/datum/getrev/New()
	commit = rustg_git_revparse("HEAD")
	if(commit)
		date = rustg_git_commit_date(commit)
	origindevcommit = rustg_git_revparse("origin/dev")

/datum/getrev/proc/load_tgs_info()
	testmerge = world.TgsTestMerges()
	var/datum/tgs_revision_information/revinfo = world.TgsRevision()
	if(revinfo)
		commit = revinfo.commit
		origindevcommit = revinfo.origin_commit
		date = revinfo.timestamp || rustg_git_commit_date(commit)

	// goes to DD log and config_error.txt
	log_world(get_log_message())

/datum/getrev/proc/get_log_message()
	var/list/msg = list()
	msg += "Running CM revision: [date]"
	if(origindevcommit)
		msg += "origin/dev: [origindevcommit]"

	for(var/line in testmerge)
		var/datum/tgs_revision_information/test_merge/tm = line
		msg += "Test merge active of PR #[tm.number] commit [tm.head_commit]"

	if(commit && commit != origindevcommit)
		msg += "HEAD: [commit]"
	else if(!origindevcommit)
		msg += "No commit information"

	return msg.Join("\n")

/datum/getrev/proc/GetTestMergeInfo(header = TRUE)
	if(!testmerge.len)
		return ""
	. = header ? "The following pull requests are currently test merged:<br>" : ""
	for(var/line in testmerge)
		var/datum/tgs_revision_information/test_merge/tm = line
		var/cm = tm.head_commit
		var/details = ": '" + html_encode(tm.title) + "' by " + html_encode(tm.author) + " at commit " + html_encode(copytext_char(cm, 1, 11))
		. += "<a href=\"[CONFIG_GET(string/githuburl)]/pull/[tm.number]\">#[tm.number][details]</a><br>"

/client/verb/showrevinfo()
	set category = "OOC"
	set name = "Show Server Revision"
	set desc = "Check the current server code revision"

	var/list/msg = list("")
	// Round ID
	if(SSperf_logging.round.id)
		msg += "<b>Round ID:</b> [SSperf_logging.round.id]"

	msg += "<b>BYOND Version:</b> [world.byond_version].[world.byond_build]"
	if(DM_VERSION != world.byond_version || DM_BUILD != world.byond_build)
		msg += "<b>Compiled with BYOND Version:</b> [DM_VERSION].[DM_BUILD]"

	// Revision information
	var/datum/getrev/revdata = GLOB.revdata
	msg += "<b>Server revision compiled on:</b> [revdata.date]"
	var/pc = revdata.origindevcommit
	if(pc)
		msg += "Dev commit: <a href=\"[CONFIG_GET(string/githuburl)]/commit/[pc]\">[pc]</a>"
	if(revdata.testmerge.len)
		msg += revdata.GetTestMergeInfo()
	if(revdata.commit && revdata.commit != revdata.origindevcommit)
		msg += "Local commit: [revdata.commit]"
	else if(!pc)
		msg += "No commit information"
	if(world.TgsAvailable())
		var/datum/tgs_version/version = world.TgsVersion()
		msg += "TGS version: [version.raw_parameter]"
		var/datum/tgs_version/api_version = world.TgsApiVersion()
		msg += "DMAPI version: [api_version.raw_parameter]"

	to_chat(src, "<span class='infoplain'>[msg.Join("<br>")]</span>")
