<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <title>Forum-Client</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.12.0-2/css/fontawesome.min.css"/>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.12.0-2/css/all.min.css"/>
    @vite('resources/css/app.css')
</head>


<body>

<div class="text-black text-3xl m-10 font-extrabold">Forums</div>
</div>
<div class="overflow-y-scroll max-h-[45rem] bg-slate-100 m-10 rounded-lg">
    <div class="grid gap-4 grid-cols-1 m-10">
        @foreach($content  as $key => $value)
            <a href="{{getenv('FORUM_CLIENT')}}/forum/{{$value->id}}/{{$value->slug}}">
                <div class="hover:bg-slate-300 rounded-md p-1.5 bg-slate-200 text-black">
                    <span class="font-extrabold">{{$value->title}}</span>
                    <br>
                    <span class="text-gray-400">{{$value->body}}</span>
                    <br>
                    <span class="text-blue-400">{{$value->status}}</span>
                    <br>Author:
                    <span class="text-blue-400">{{$value->author_id}}</span>
                    <div>
                        <a href="{{getenv('FORUM_CLIENT')}}/editForum/{{$value->id}}/{{$value->slug}}?apikey={{getenv('API_KEY')}}">
                            <button class="bg-blue-900 rounded-lg p-1 text-white hover:bg-blue-600"><i class="fa fa-pen"></i></button>
                        </a>
                        <a href="{{getenv('FORUM_CLIENT')}}/deleteForum/{{$value->id}}?apikey={{getenv('API_KEY')}}">
                            <button class="bg-blue-900 rounded-lg p-1 text-white hover:bg-blue-600"><i class="fa fa-trash"></i></button>
                        </a>
                    </div>
                </div>
            </a>
        @endforeach
    </div>
</div>

<div class="m-10 text-center">
    <a href="{{getenv('FORUM_CLIENT')}}/createForum">
        <button class="bg-blue-900 rounded-lg p-1 text-white hover:bg-blue-600">Create Forum</button>
    </a>
    <a href="{{getenv('FORUM_CLIENT')}}/deleteAllForum">
        <button class="bg-blue-900 rounded-lg p-1 text-white hover:bg-blue-600">Remove All</button>
    </a>
</div>
</body>
</html>
