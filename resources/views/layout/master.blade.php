<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <title>
        @yield('title')
    </title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.12.0-2/css/fontawesome.min.css"/>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.12.0-2/css/all.min.css"/>
    @vite('resources/css/app.css')
</head>

<body>

@isset($errors)
    @if ($errors->any())
        <div class="alert alert-danger m-5">
            <ol>
                @foreach ($errors->all() as $error)
                    <li>{{ $error }}</li>
                @endforeach
            </ol>
        </div>
    @endif
@endisset

<div class="flex flex-row">
    <div class="">
        <a href="{{getenv('FORUM_CLIENT')}}"><i class="fas fa-home fa-2x"></i></a>
    </div>
    <div class="grow p-5">
        <i class="fab fa-sistrix fa-1x"></i>
        <input class="border-black border-solid border-2 rounded-lg" type="text" id="search" name="search" placeholder="Search Forum">
    </div>
    <div class="">
        @if(Session::has('author_id'))
            Welcome:{{Session::get('author_id')}}
            <a href="{{getenv('FORUM_CLIENT')}}/destroyLogin">Logout</a>
        @else
            <a class="rounded-full w-200 border-solid border-2 border-b-blue-900 text-white bg-blue-800 p-2" href="{{getenv('FORUM_CLIENT')}}/login">Login</a>
            <a href="{{getenv('FORUM_CLIENT')}}/register">Register</a>
        @endif
    </div>
</div>
@yield('content')

@yield('footer')
</body>
</html>
