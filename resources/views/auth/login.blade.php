@extends('layout.master')
@section('content')
    <div class="text-black text-2xl m-10 font-extrabold">Login</div>
    <div class="overflow-y-scroll bg-stone-500 m-10 rounded-lg">
        <form class="bg-slate-200 p-5" method="POST" action="{{getenv('FORUM_CLIENT')}}/storeLogin">
            @csrf

            <div class="mt-4">
                <label for="email">Email</label>
                <input class="block mt-1 w-full" type="text" name="email" id="email" value="{{old('email')}}" required autofocus>
            </div>

            <div class="mt-4">
                <label for="password">Password</label>
                <input class="block mt-1 w-full" type="password" name="password" id="password" required autocomplete="current_password">
            </div>

            <div class="mt-4">
                <label class="inline-flex items-center" for="remember_me">Name</label>
                <input class="block mt-1 w-full" type="checkbox" name="remember_me" id="remember_me">
            </div>

            <div class="block mt-4">
                <label for="remember_me" class="inline-flex items-center">
                    <input id="remember_me" type="checkbox" class="rounded border-gray-300 text-indigo-600 shadow-sm focus:ring-indigo-500" name="remember">
                    <span class="ml-2 text-sm text-gray-600">Remember me</span>
                </label>
            </div>

            <div class="flex items-center justify-end mt-4">
                @if (Route::has('password.request'))
                    <a class="underline text-sm text-gray-600 hover:text-gray-900 rounded-md focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500" href="">Forgot your password?</a>
                @endif

                <button class="ml-3">Log in</button>
            </div>
        </form>
    </div>
@endsection
