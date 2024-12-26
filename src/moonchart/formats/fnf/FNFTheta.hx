package moonchart.formats.fnf;

import moonchart.backend.FormatData;
import moonchart.backend.Util;
import moonchart.formats.BasicFormat;

typedef FNFThetaFormat = Array<FNFThetaStrumline>;
typedef FNFThetaMeta = Array<FNFThetaEvent>;

typedef FNFThetaStrumline =
{
	is_player:Bool,
	character:Int,
	notes:Array<FNFThetaNote>
}

typedef FNFThetaNote =
{
	time:Float,
    holdlength:Float,
	direction:Int,
	type:String,
	properties:Map<String, Any>
}

typedef FNFThetaEvent =
{
    type:String,
	time:Float,
	properties:Map<String, Any>
}

class FNFTheta extends BasicJsonFormat<FNFThetaFormat, FNFThetaMeta>
{
    public static function __getFormat():FormatData
    {
        return {
            ID: FNF_THETA,
            name: "FNF (Theta)",
            description: "the 🐎 engine : )",
            extension: "json",
            hasMetaFile: POSSIBLE,
            metaFileExtension: "json",
            handler: FNFTheta
        }
    }

    public function new(?data:FNFThetaFormat, ?meta:FNFThetaMeta)
    {
        super({timeFormat: STEPS, supportsDiffs: false, supportsEvents: true});
        this.data = data;
        this.meta = meta;
        beautify = true;
    }

    override function fromBasicFormat(chart:BasicChart, ?diff:FormatDifficulty):FNFTheta
    {
        var chartResolve = resolveDiffsNotes(chart, diff);
		var basicNotes:Array<BasicNote> = chartResolve.notes.get(chartResolve.diffs[0]);
        var meta = chart.meta;

        final bpm = chart.meta.bpmChanges[0];

        // you probably only need two? write code for gf note stuff l8r
        var strumlines:Array<FNFThetaStrumline> = Util.makeArray(2);
        for (i in 0...2)
        {
            strumlines[i] = {
                is_player: i == 0,
                character: i,
                notes: []
            }
        }

        final secPerBeat = 60 / bpm.bpm;
        final secPerStep = secPerBeat / 4;

        for (note in basicNotes)
        {
            var lane:Int = note.lane;
            var strumline:FNFThetaStrumline = strumlines[Std.int(lane / 4)];

            if (strumline == null)
                continue;

            var direction:Int = lane % 4;
            
            var noteBeat = (note.time / 1000) / secPerStep;
            var holdBeat = (note.length / 1000) / secPerStep;

            strumline.notes.push({
                time: noteBeat,
                holdlength: holdBeat,
                direction: direction,
                type: "",
                properties: []
            });
        }

        // Push normal events / cam movement events
		var basicEvents = chart.data.events;
		var events:Array<FNFThetaEvent> = Util.makeArray(basicEvents.length);

		for (i in 0...basicEvents.length)
		{
			final event = basicEvents[i];
			final isFocus:Bool = FNFGlobal.isCamFocus(event);

            // TODO: other events maybe
            if (isFocus) {
                Util.setArray(events, i, {
                    type: "set_camera_target",
                    time: event.time / 1000,
                    properties: [
                        "character" => resolveCamFocus(event)
                    ]});
            }
		}

        events.sort((a, b) -> return Util.sortValues(a.time, b.time));

        this.data = strumlines;
        this.meta = events;

        return this;
    }

    function resolveCamFocus(event:BasicEvent):Int
    {
        return switch (FNFGlobal.resolveCamFocus(event))
        {
            case BF: 1;
            case DAD: 0;
            case GF: 2;
        }
    }
}