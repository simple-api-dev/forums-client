<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <title>Laravel</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    @vite('resources/css/app.css')
</head>

<body>
<p class="bg-midnight text-3xl font-bold underline">Forums</p>
<div>


    @foreach($content  as $key => $value)
    <ul>
        <li><a href="">~</a>
            <a href="">x</a>
            <a href="">{{$value->id}}</a>
            <a href="">{{$value->title}}</a>
            <a href="">{{$value->slug}}</a>
            <a href="">{{$value->body}}</a>
            <a href="">{{$value->status}}</a>
            <a href="">{{$value->author_id}}</a>
        </li>
    </ul>
    @endforeach
    <a href="">+</a>
</div>

</body>
</html>
