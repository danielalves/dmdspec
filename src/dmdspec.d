module dmdspec;

import std.stdio;
import std.conv;
import std.array;
import std.traits;
import std.exception;
import std.Variant;

import exampleResult;
public import matchers;
public import dsl;

class SpecFailureException : Exception {
	Variant expectation;
	Variant got;
	
	this(string message) {
		super(message);
	}
}

class Subject(T) {
	private T object;
	
	this() {
		this.object = T.init; // default initializer
	}
	
	this(T object) {
		this.object = object;
	}
	
	bool should(T condition) {
		bool result = this.object == condition;
		if (!result) {
			auto exception = new SpecFailureException("");
			exception.expectation = this.object;
			exception.got = condition;
			throw exception;
		}
		return result;
	}
	
	@property bool shouldThrowException( E )() {
		static if( isCallable!( T ) )
			Exception ex = collectException( object() );
		else
			Exception ex = collectException( object );
			
		if ( ( ex is null ) || ( typeid( ex ) != typeid( E ) ) ) {
			throw new SpecFailureException("");
		}
		return true;
	}
	
	void writeType()
	{
		writeln( typeof( object ).stringof );
	}
}

class Reporter {
	static int level = 0;
	static int examplesIndex = 0;
	static ExampleResult[] failures;
	static string[] describes;
		
	static this() {
		write("\n");
	}
	
	static ~this() {
		auto failuresCount = failures.length;
		
		writeln("\nFailures:");
		foreach(int i, ExampleResult example ; failures) {
			writefln("\n  %d) %s", i + 1, example.getMessage());
			writefln(red("     expectation: %s"), to!(string)(example.getExpectation()));
			writefln(red("             got: %s"), to!(string)(example.getGot()));
		}
		
		writefln(
			"\nFinished! %d examples, %d %s", 
			examplesIndex, 
			failuresCount,
			failuresCount > 1 ? "failures" : "failure"
		);
	}
			
	static void report(ExampleResult example) {
		examplesIndex++;
		if (example.isSuccess()) {
			writefln("%s%s", createLevel(), green(example.getDescription()));
			
		} else {
			example.setMessage(createContext(example.getDescription()));
			string number = to!(string)(failures.length + 1);
			
			writefln(red("%s%s - (#%s)"), createLevel(), example.getDescription(), number);
			failures ~= example;
		}
	}
	
	static void report(string description, void delegate() intention) {
		describes ~= description;
		
		writefln("%s%s", createLevel(), description);
		level++;
		intention();
		level--;
	}
	
	private static string createContext(string description) {
		string[] prefix;			
		for(int i = 0; i < level - 1; i++) {
			prefix ~= describes[i];
		}
			
		return join(appender(prefix).data, " ") ~ " " ~ description;
	}
		
	private static string createLevel() {
		string[] str = [];
		auto app = appender(str);
		for (int x = 0; x < level; x++) {
			app.put("  ");
		}
		return join(app.data);
	}
		
	private static string color(string text, string colorCode) {
		return colorCode ~ text ~ "\033[0m";
	}
	
	private static string green(string text) {
		return color(text, "\033[32m");
	}
	
	private static string red(string text) {
		return color(text, "\033[31m");
	}
}
