<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <title>Forum-Client</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    @vite('resources/css/app.css')
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.12.0-2/css/fontawesome.min.css"/>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.12.0-2/css/all.min.css"/>
</head>


<body>
<p class="bg-amber-800">FORUMS</p>
@foreach($content  as $key => $value)
    <ul>
        <li>
            <a href="{{getenv('FORUM_CLIENT')}}/editForum/{{$value->slug}}?apikey={{getenv('API_KEY')}}"><i
                    class="fa fa-pen"></i></a>
            <a href="{{getenv('FORUM_CLIENT')}}/deleteForum/{{$value->id}}?apikey={{getenv('API_KEY')}}"><i
                    class="fa fa-trash"></i></a>
            <a class="underline" href="http://127.0.0.1:8000/forum/{{$value->slug}}">{{$value->title}}</a><br>
            {{$value->body}} [{{$value->status}}]
        </li>
    </ul>
@endforeach
<a href="{{getenv('FORUM_CLIENT')}}/createForum"><i class="fa fa-plus"></i></a>
</body>
</html>
