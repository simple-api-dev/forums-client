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


<p>Topic</p>
<div>
    <ul>
        <li><a href="">~</a>
            <a href="">x</a>
            <a href="">{{$forum_content->slug}}</a>
        </li>
    </ul>
    <a href="">+</a>
</div>

<p>Moderators</p>
<div>
    @foreach($moderators_content as $item)
        <ul>
            <li><a href="">~</a>
                <a href="">x</a>
                <a href="">{{$item->author_id}}</a>
                <a href="">{{$item->status}}</a>
            </li>
        </ul>
    @endforeach
    <a href="">+</a>
</div>


<p class="bg-cyan-500">Rules</p>
<div>
    @foreach($rules_content as $item)
        <ul>
            <li><a href="">~</a>
                <a href="">x</a>
                <a href="">{{$item->body}}</a>
                <a href="">{{$item->status}}</a>
            </li>
        </ul>
    @endforeach
    <a href="">+</a>
</div>


<p>topics</p>
<div>
    @foreach($topics_content as $item)
        <ul>
            <li><a href="">~</a>
                <a href="">x</a>
                <a href=""><B>{{$item->title}}</B></a>
                <a href=""><u>{{$item->slug}}</u></a>
                <a href="">{{$item->body}}</a>
                <a href="">{{$item->type}}</a>
                <a href="">{{$item->status}}</a>
                <a href="">{{$item->author_id}}</a>
                {{--
                <a href="">{{$item->tag_names}}</a>
                <a href="">{{$item->reports}}</a>
                --}}
            </li>
        </ul>
    @endforeach
    <a href="">+</a>
</div>
</body>
</html>
