import os
from crewai import Agent, Crew, Process, Task, LLM

# Use Gemini via LiteLLM integration built into CrewAI
gemini_llm = LLM(
    model="gemini/gemini-2.5-flash",
    api_key=os.environ.get("GEMINI_API_KEY")
)

# 1. Define the Agents
researcher = Agent(
    role='Senior Technical Researcher',
    goal='Gather and analyze requirements, APIs, and edge cases for a given problem.',
    backstory='Meticulous researcher who extracts precise technical details and constraints.',
    llm=gemini_llm,
    verbose=True
)

architect = Agent(
    role='Software Architect',
    goal='Design robust, scalable system architectures and module layouts based on research.',
    backstory='Pragmatic designer focusing on clean separation of concerns and maintainability.',
    llm=gemini_llm,
    verbose=True
)

implementer = Agent(
    role='Software Implementer',
    goal='Write clean, production-ready code implementing the architecture design.',
    backstory='Expert developer who translates specifications into clean, working code.',
    llm=gemini_llm,
    verbose=True
)

# 2. Define a sample task pipeline
task_research = Task(
    description='Research the best approach to build a lightweight CLI log parser in Python.',
    expected_output='A summary of required libraries, parsing strategies, and edge cases.',
    agent=researcher
)

task_design = Task(
    description='Design the module structure and class hierarchy for the log parser based on the research.',
    expected_output='An architectural outline with file names, class definitions, and data flow.',
    agent=architect
)

task_code = Task(
    description='Implement the core Python script based on the architectural design.',
    expected_output='Complete, runnable Python code block.',
    agent=implementer
)

# 3. Assemble the Crew
dev_crew = Crew(
    agents=[researcher, architect, implementer],
    tasks=[task_research, task_design, task_code],
    process=Process.sequential,
    verbose=True
)

if __name__ == "__main__":
    print("--- Starting Multi-Agent Pipeline ---")
    result = dev_crew.kickoff()
    print("\n--- Final Output ---")
    print(result)
