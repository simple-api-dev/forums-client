<?php

use App\Http\Controllers\commentController;
use App\Http\Controllers\ForumController;
use App\Http\Controllers\ForumTagsController;
use App\Http\Controllers\LoginUserController;
use App\Http\Controllers\ModeratorController;
use App\Http\Controllers\RegisteredUserController;
use App\Http\Controllers\ReportController;
use App\Http\Controllers\RuleController;
use App\Http\Controllers\TopicController;
use App\Http\Controllers\topicShowController;
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

Route::get('/forum/{id}/{slug}', [ForumController::class, 'show'], 'id', 'slug');

Route::get('/createForum', [ForumController::class, 'create']);
Route::post('/storeForum', [ForumController::class, 'store']);
Route::get('/deleteForum/{id}', [ForumController::class, 'destroy'], 'id');
Route::get('/editForum/{id}/{slug}', [ForumController::class, 'edit'], 'id','slug');
Route::post('/updateForum', [ForumController::class, 'update']);

Route::get('/createForumTag/{forum_id}/{forum_slug}', [ForumTagsController::class, 'create'], 'forum_id', 'forum_slug');
Route::post('/storeForumTag', [ForumTagsController::class, 'store']);
Route::get('/deleteForumTag/{forum_id}/{forum_slug}/{id}', [ForumTagsController::class, 'destroy'], 'forum_id', 'forum_slug', 'id');

Route::get('/createModerator/{forum_id}/{forum_slug}', [ModeratorController::class, 'create'], 'forum_id', 'forum_slug');
Route::post('/storeModerator', [ModeratorController::class, 'store']);
Route::get('/deleteModerator/{forum_id}/{forum_slug}/{id}', [ModeratorController::class, 'destroy'], 'forum_id', 'forum_slug', 'id');
Route::post('/updateModerator', [ModeratorController::class, 'update']);

Route::get('/createRule/{forum_id}/{forum_slug}', [RuleController::class, 'create'],'forum_id', 'forum_slug');
Route::post('/storeRule', [RuleController::class, 'store']);
Route::get('/deleteRule/{forum_id}/{forum_slug}/{id}', [RuleController::class, 'destroy'], 'forum_id', 'forum_slug', 'id');
Route::get('/editRule/{forum_id}/{forum_slug}/{id}', [RuleController::class, 'edit'], 'forum_id', 'forum_slug', 'id');
Route::post('/updateRule', [RuleController::class, 'update']);
Route::get('/deleteAllRule/{forum_id}/{forum_slug}', [RuleController::class, 'destroyAll'], 'forum_id', 'forum_slug');

Route::get('/createTopic/{forum_id}/{forum_slug}', [TopicController::class, 'create'], 'forum_id','forum_slug');
Route::post('/storeTopic', [TopicController::class, 'store']);
Route::get('/deleteTopic/{forum_id}/{forum_slug}/{id}', [TopicController::class, 'destroy'], 'forum_id','forum_slug', 'id');
Route::get('/editTopic/{forum_id}/{forum_slug}/{slug}', [TopicController::class, 'edit'], 'forum_id','forum_slug', 'slug');
Route::post('/updateTopic', [TopicController::class, 'update']);

Route::get('/reportTopic/{forum_id}/{forum_slug}/{id}', [ReportController::class, 'report'], 'forum_id','forum_slug', 'id');
Route::get('/approveReport/{forum_id}/{forum_slug}/{id}', [ReportController::class, 'approveReport'], 'forum_id', 'forum_slug', 'id');
Route::get('/declineReport/{forum_id}/{forum_slug}/{id}', [ReportController::class, 'declineReport'], 'forum_id', 'forum_slug', 'id');

Route::get('/upvoteTopic/{forum_id}/{forum_slug}/{id}', [TopicController::class, 'upvote'], 'forum_id', 'forum_slug', 'id');
Route::get('/downvoteTopic/{forum_id}/{forum_slug}/{id}', [TopicController::class, 'downvote'], 'forum_id', 'forum_slug', 'id');

Route::get('/topicShow/{forum_id}/{forum_slug}/{topic_id}/{topic_slug}', [topicShowController::class, 'show'], 'forum_id', 'forum_slug', 'topic_id', 'topic_slug');
Route::post('/storeCommentPost', [commentController::class, 'store']);
Route::get('/deleteComment/{forum_id}/{forum_slug}/{topic_id}/{topic_slug}/{id}', [commentController::class, 'destroy'], 'forum_id', 'forum_slug', 'topic_id', 'topic_slug', 'id');
Route::post('/storeCommentCommentPost', [commentController::class, 'storeCommentComment']);

Route::get('/register', [RegisteredUserController::class, 'create']);
Route::post('/storeRegister', [RegisteredUserController::class, 'store']);

Route::post('/storeLogin', [LoginUserController::class, 'store']);
Route::get('/destroyLogin', [LoginUserController::class, 'destroy']);
Route::get('/login', [LoginUserController::class, 'create']);


