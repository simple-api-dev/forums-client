<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rules;

class RegisteredUserController extends Controller
{
    public function create()
    {
        return view('auth.register');
    }


    public function store(Request $request)
    {
        $validate = Validator::make($request->all(), [
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'string', 'email', 'max:255'],
            'password' => ['required', 'confirmed', Rules\Password::defaults()],
        ]);

        if ($validate->fails()) {
            return back()->withErrors($validate->errors())->withInput();
        }

        $request_data = $request->all();
        $response = HTTP::post(getenv('AUTH_SITE') . '/register/?apikey=' . getenv('AUTH_APIKEY'), [
            'integration_id' => getenv('INTEGRATION_ID'),
            'name' => $request_data['name'],
            'email' => $request_data['email'],
            'password' => Hash::make($request_data['password']),
        ]);

        if (!$response->successful()) {
            $response = json_decode($response);
            $validate->getMessageBag()->add('message', $response->message);
            return back()->withErrors($validate->errors())->withInput();
        }

        $response = json_decode($response);
        $message = $response->message;
        return view('auth.registerSuccessful', compact('message','message'));
    }
}
