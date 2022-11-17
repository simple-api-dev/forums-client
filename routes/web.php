<?php

use App\Http\Controllers\ForumController;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\ForumsController;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| contains the "web" middleware group. Now create something great!
|
*/


Route::get('/', [ForumsController::class, 'show']);

Route::get('/forum/{slug}', [ForumController::class, 'show'], 'slug');
Route::get('/createForum', [ForumController::class, 'create']);
Route::post('/storeForum', [ForumController::class, 'store']);
Route::get('/deleteForum/{id}', [ForumController::class, 'destroy'], 'id');
Route::get('/editForum/{slug}', [ForumController::class, 'edit'], 'slug');
Route::post('/updateForum', [ForumController::class, 'update']);

