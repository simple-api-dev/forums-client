<?php

use App\Http\Controllers\CommentOnTopicController;
use App\Http\Controllers\ForumController;
use App\Http\Controllers\ForumTagsController;
use App\Http\Controllers\ModeratorController;
use App\Http\Controllers\RuleController;
use App\Http\Controllers\TopicController;
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

Route::get('/createForumTag/{id}', [ForumTagsController::class, 'create'], 'id');
Route::post('/storeForumTag', [ForumTagsController::class, 'store']);

Route::get('/createModerator/{id}', [ModeratorController::class, 'create'], 'id');
Route::post('/storeModerator', [ModeratorController::class, 'store']);
Route::get('/deleteModerator/{id}', [ModeratorController::class, 'destroy'], 'id');
Route::get('/editModerator/{id}', [ModeratorController::class, 'edit'], 'id');
Route::post('/updateModerator', [ModeratorController::class, 'update']);

Route::get('/createRule/{id}', [RuleController::class, 'create'], 'id');
Route::post('/storeRule', [RuleController::class, 'store']);
Route::get('/deleteRule/{id}', [RuleController::class, 'destroy'], 'id');
Route::get('/editRule/{id}', [RuleController::class, 'edit'], 'id');
Route::post('/updateRule', [RuleController::class, 'update']);
Route::get('/deleteAllRule/{id}', [RuleController::class, 'destroyAll'], 'id');

Route::get('/createTopic/{id}', [TopicController::class, 'create'], 'id');
Route::post('/storeTopic', [TopicController::class, 'store']);
Route::get('/deleteTopic/{id}', [TopicController::class, 'destroy'], 'id');
Route::get('/editTopic/{slug}', [TopicController::class, 'edit'], 'slug');
Route::post('/updateTopic', [TopicController::class, 'update']);

Route::get('/upvoteTopic/{id}', [TopicController::class, 'upvote'], 'id');
Route::get('/downvoteTopic/{id}', [TopicController::class, 'upvote'], 'id');

Route::get('/createCommentOnTopic/{id}', [CommentOnTopicController::class, 'create'], 'id');
Route::post('/storeCommentOnTopic', [CommentOnTopicController::class, 'store']);
Route::get('/deleteCommentOnTopic/{id}', [CommentOnTopicController::class, 'destroy'], 'id');
Route::get('/editCommentOnTopic/{slug}', [CommentOnTopicController::class, 'edit'], 'slug');
Route::post('/updateCommentOnTopic', [CommentOnTopicController::class, 'update']);

