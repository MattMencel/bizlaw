import { Controller, Get, Render, Param } from '@nestjs/common';
import axios from 'axios';

@Controller('cases')
export class CasesController {
  private apiUrl = process.env.API_URL || 'http://localhost:3333';

  @Get()
  @Render('cases/index')
  async findAll() {
    try {
      const { data } = await axios.get(`${this.apiUrl}/api/cases`);
      return {
        cases: data,
        title: 'All Cases',
      };
    } catch (error) {
      console.error('Error fetching cases:', error);
      return {
        cases: [],
        error: 'Failed to load cases',
        title: 'All Cases',
      };
    }
  }

  @Get(':id')
  @Render('cases/detail')
  async findOne(@Param('id') id: string) {
    try {
      const { data: caseData } = await axios.get(
        `${this.apiUrl}/api/cases/${id}`,
      );
      const { data: events } = await axios.get(
        `${this.apiUrl}/api/case-events/case/${id}`,
      );

      return {
        case: caseData,
        events,
        title: caseData.title,
      };
    } catch (error) {
      console.error('Error fetching case details:', error);
      return {
        case: null,
        events: [],
        error: 'Failed to load case details',
        title: 'Case Details',
      };
    }
  }
}
