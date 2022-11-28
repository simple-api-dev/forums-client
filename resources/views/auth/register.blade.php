@extends('layout.master')
@section('content')
    <div class="text-black text-2xl m-10 font-extrabold">Register</div>
    <div class="overflow-y-scroll bg-stone-500 m-10 rounded-lg max-w-sm">

        <form class="bg-slate-200 p-5" method="POST" action="{{getenv('FORUM_CLIENT')}}/storeRegister">
            @csrf

            <div class="mt-4">
                <label for="name">Name</label>
                <input class="block mt-1 w-full" type="text" name="name" id="name" value="{{old('name')}}" required autofocus>
            </div>

            <div class="mt-4">
                <label for="email">Email</label>
                <input class="block mt-1 w-full" type="text" name="email" id="email" value="{{old('email')}}" required>
            </div>

            <div class="mt-4">
                <label for="password">Password</label>
                <input class="block mt-1 w-full" type="password" name="password" id="password" required autocomplete="new_password">
            </div>

            <div class="mt-4">
                <label for="password_confirmation">Confirm Password</label>
                <input class="block mt-1 w-full" type="password" name="password_confirmation" id="password_confirmation" required>
            </div>

            <div class="flex items-center justify-end mt-4">
                <a class="underline text-sm text-gray-600 hover:text-gray-900 rounded-md focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500" href="{{getenv('FORUM_CLIENT')}}/login">Already registered?</a>
                <button class="ml-4" type="submit">Register</button>
            </div>
        </form>

    </div>
@endsection
