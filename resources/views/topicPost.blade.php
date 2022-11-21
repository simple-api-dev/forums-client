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


<div class="flex h-screen">
    <div class="flex-1 flex flex-col overflow-hidden">
        <header class="flex justify-between items-center bg-gray-300 p-4 rounded-lg">
            <div class="flex">
                <button class="bg-blue-800 rounded-lg p-3 text-white hover:bg-blue-600">
                    <a href="{{getenv('FORUM_CLIENT')}}">Forums</a>
                </button>
            </div>
            <div class="flex">
                <button class="bg-blue-800 rounded-lg p-3 text-white hover:bg-blue-600">
                    <a href="{{getenv('FORUM_CLIENT')}}/createTopic/{{$forum_content->id}}/{{$forum_content->slug}}?apikey={{getenv('API_KEY')}}">Create New Topic</a>
                </button>
            </div>
            <div class="flex max-w-[70%]">
                <span>
                <span class="text-black font-extrabold">{{$forum_content->title}}</span><br>
                {{$forum_content->body}}
                    </span>
            </div>
            <div class="flex">
                Login
            </div>
        </header>

        <div class="flex max-h-[90%]">
            <main class="flex flex-col w-full bg-white overflow-y-auto overflow-x-auto">
                <div>
                    POST
                </div>
            </main>
        </div>
    </div>
</div>


</body>
</html>
