@extends('layout.master')
@section('content')
    <div class="text-black text-2xl m-10 font-extrabold">Forgot Password</div>
    <div class="overflow-y-scroll bg-stone-500 m-10 rounded-lg">
        <div class="mb-4 text-sm text-gray-600">Forgot your password? No problem. Just let us know your email address and we will email you a password reset link that will allow you to choose a new one.</div>

        @if ($status)
            <div class="mb-4 font-medium text-sm text-green-600">
                {{ session('status') }}
            </div>
        @endif

        <form class="bg-slate-200 p-5" method="POST" action="">
            @csrf

            <div class="mt-4">
                <label for="email">Email</label>
                <input class="block mt-1 w-full" type="text" name="email" id="email" value="old('email')" required autofocus>
            </div>

            <div class="flex items-center justify-end mt-4">
                <button class="ml-3">Email Password Reset Link</button>
            </div>
        </form>
    </div>
@endsection
