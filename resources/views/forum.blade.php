<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <title>Laravel</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="resources/css/app.css">
</head>

<body>
<p><b>Forum</b></p>


<p>Moderators</p>
<div>
    @foreach($moderators_content as $item)
        <ul>
            <li>
                <a href="{{getenv('FORUM_CLIENT')}}/editModerator/{{$item->id}}?apikey={{getenv('API_KEY')}}">~</a>
                <a href="{{getenv('FORUM_CLIENT')}}/deleteModerator/{{$item->id}}?apikey={{getenv('API_KEY')}}">x</a>
                <div>{{$item->author_id}} [{{$item->status}}]</div>
            </li>
        </ul>
    @endforeach
    <a href="{{getenv('FORUM_CLIENT')}}/createModerator/{{$forum_content->id}}?apikey={{getenv('API_KEY')}}">+</a>
</div>


<p>Rules</p>
<div>
    @foreach($rules_content as $item)
        <ul>
            <li>
                <a href="{{getenv('FORUM_CLIENT')}}/editRule/{{$item->id}}?apikey={{getenv('API_KEY')}}">~</a>
                <a href="{{getenv('FORUM_CLIENT')}}/deleteRule/{{$item->id}}?apikey={{getenv('API_KEY')}}">x</a>
                <div>{{$item->body}} [{{$item->status}}]</div>
            </li>
        </ul>
    @endforeach

    <a href="{{getenv('FORUM_CLIENT')}}/createRule/{{$forum_content->id}}?apikey={{getenv('API_KEY')}}">+</a>
</div>


<p>Topics</p>
<div>
    @foreach($topics_content as $item)
        <ul>
            <li>
                <a href="{{getenv('FORUM_CLIENT')}}/editTopic/{{$item->slug}}?apikey={{getenv('API_KEY')}}">~</a>
                <a href="{{getenv('FORUM_CLIENT')}}/deleteTopic/{{$item->slug}}?apikey={{getenv('API_KEY')}}">x</a>
                <a href=""><B>{{$item->title}}</B></a>
                <a href=""><u>{{$item->slug}}</u></a>
                <a href="">{{$item->body}}</a>
                <a href="">{{$item->type}}</a>
                <a href="">{{$item->status}}</a>
                <a href="">{{$item->author_id}}</a>
                <div>Tags:</div>
                @foreach($item->tag_names as $tag)
                    <b>{{$tag}}</b> |
                @endforeach
                <div>Reports:</div>
                <ul>
                @foreach($item->reports as $report)
                        <li>{{$report->id}} | {{$report->author_id}} | {{$report->status}} | {{$report->type}}</li>
                @endforeach
                </ul>
                Score:{{$item->score}}
            </li>
        </ul>
    @endforeach
    <a href="{{getenv('FORUM_CLIENT')}}/createTopic/{{$forum_content->id}}?apikey={{getenv('API_KEY')}}">+</a>
</div>
</body>
</html>
